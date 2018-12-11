class UserApplication < ActiveRecord::Base
	belongs_to :user, inverse_of: :user_applications
	belongs_to :oauth_application
	belongs_to :invited_by, class_name: User
	belongs_to :assigned_to, class_name: User

	validates_presence_of :user, :oauth_application

	def self.find_by_invitation_token(original_token)
		find_token = Devise.token_generator.digest(self, :invitation_token, original_token)
		find_by(invitation_token: find_token)
	end

	def current_invitation_expires_at
		current_invitation_sent_at + invitation_expires_in if current_invitation_sent_at.present? && invitation_expires_in.present?
	end

	def expire
		if invitation_status == 'expired' && self[:invitation_status] != 'expired'
			UserMailer.delay.invitation_expired_invitee(self.id, self.invitation_token_raw)
			UserMailer.delay.invitation_expired_inviter(self.id, self.invitation_token_raw) if self.invited_by_id.present?
			self.update_attributes(invitation_status: 'expired')
			RceHelper.is?(self) do
				RceHelper.update_user_auth_status(self.user)
			end unless Rails.env.development?
		end
	end

	def remind
		if reminded == false && %(invited re-invited).include?(invitation_status) && invitation_expires_in > 3.days
			UserMailer.delay.invitation_reminder(self.id, self.invitation_token_raw, 2.days.to_i)
			self.update_attributes(reminded: true)
		end
	end

	def deactivate
		if invitation_status != 'inactive'
			self.update_attributes(invitation_status: 'inactive', invitation_token_raw: nil, invitation_token: nil)
			RceHelper.is?(self) do
				RceHelper.update_user_auth_status(self.user)
			end unless Rails.env.development?
		end
	end

	def complete(skip_expired_check=false)
		if invitation_status != 'complete' && (invitation_status != 'expired' || skip_expired_check)
			self.update_attributes(invitation_status: 'complete', invitation_token_raw: nil, invitation_token: nil)
			RceHelper.is?(self) do
				self.user.update_from_rce
				RceHelper.update_user_auth_status(self.user)
			end unless Rails.env.development?
		else
			RceHelper.is?(self) do
				self.user.update_from_rce
			end unless Rails.env.development?
		end
	end

	def self.expire_invites
		for_invitation_status('expired').where.not(invitation_status: 'expired').each do |ua|
			ua.expire
		end
	end

	def self.remind_invites
		remind_at = Arel::Nodes::SqlLiteral.new("(current_invitation_sent_at+(invitation_expires_in-#{2.days.to_i}) * interval '1 second')")
		for_invitation_status('invited').
				where(reminded: false).
				where.not(current_invitation_sent_at: nil).
				where('invitation_expires_in > ?', 3.days.to_i).
				where(remind_at.lt(DateTime.now.utc)).each do |ua|
			ua.remind
		end
	end

	def self.for_invitation_status(status)
		t = UserApplication.arel_table
		expires_at = Arel::Nodes::SqlLiteral.new("(current_invitation_sent_at+invitation_expires_in * interval '1 second')")

		if status == 'expired'
			where(t[:invitation_status].eq(status).
					or(t[:invitation_status].in(%w(invited re-invited)).and(t[:current_invitation_sent_at].eq(nil).not).and(t[:invitation_expires_in].eq(nil).not).and(expires_at.lt(DateTime.now.utc)))
			)
		elsif %w(invited re-invited).include?(status)
			where(t[:invitation_status].eq(status).
					and(t[:current_invitation_sent_at].eq(nil).
						or(t[:invitation_expires_in].eq(nil)).
						or(expires_at.gt(DateTime.now.utc))
					)
			)
		else
			where(t[:invitation_status].eq(status))
		end
	end

	def invitation_status
		return 'expired' if current_invitation_sent_at.present? && !current_invitation_expires_at.nil? && current_invitation_expires_at < DateTime.now.utc && %w(invited re-invited).include?(self[:invitation_status])
		return self[:invitation_status]
	end

	def invitation_status_name
		invitation_status
	end

	def invited_by_name
		self.invited_by.try(:name)
	end
	def invited_by_email
		self.invited_by.try(:email)
	end
	def invited_by_from_name
		" from #{invited_by_name}" if invited_by_name.present?
	end

	def invite(invited_by_id = nil, expires_in = nil, send = true)
		self.invitation_expires_in = expires_in if expires_in.present?
		self.current_invitation_sent_at = DateTime.now
		self.first_invitation_sent_at = current_invitation_sent_at if first_invitation_sent_at.nil?
		self.invited_by_id = invited_by_id if invited_by_id.present?
		self.reminded = false
		if self.postpone_invite
			self.invitation_status = 'invited' if self.invitation_status == 'inactive' && self.postpone_invite && self.request_status == 'complete'
		else
			self.invitation_status = self.first_invitation_sent_at == self.current_invitation_sent_at ? 'invited' : 're-invited'
		end
		if %w(invited re-invited).include?(self.invitation_status)
			raw, enc = Devise.token_generator.generate(self.class, :invitation_token)
			self.invitation_token = enc
			self.invitation_token_raw = raw
			self.save! if self.persisted?

			Rails.logger.info("Created invitation user '#{user.username}'#{self.external_id.present? ? ", ext id: '#{self.external_id}'" : ''}, app: '#{oauth_application.name}'")

			RceHelper.is?(self) do
				RceHelper.update_user_auth_status(self.user)
			end

			run_at = (oauth_application.invitation_delay_seconds || 0).seconds.from_now

			if send
				UserMailer.delay(run_at: run_at).invitation(self.id, raw, expires_in.to_i)
			end
		end
	end

	def request_new_invite
		if self.invited_by_id.present?
			UserMailer.delay.invitation_rerequested_inviter(self.id)
		end
	end

	def notify_assignment
		UserMailer.delay(run_at: 3.minutes.from_now).request_assigned_requester(self.id)
		UserMailer.delay(run_at: 3.minutes.from_now).request_assigned_assignee(self.id)
	end

	def is_blocked_due_to_status?
		%w(expired inactive).include? invitation_status
	end

	def custom_label_method
		self.oauth_application.try(:name)
	end

	rails_admin do
		object_label_method do
			:custom_label_method
		end
		parent User
		list do
			include_fields :user, :oauth_application, :external_id, :postpone_invite, :request_status, :assigned_to, :form_submit_id
			field :invitation_status_name do
				label 'Invitation Status'
			end
			include_fields :invited_by, :created_at
		end
		show do
			include_fields :user, :oauth_application, :external_id, :postpone_invite, :request_status, :assigned_to, :form_submit_id
			field :invitation_status_name do
				label 'Invitation Status'
			end
			field :current_invitation_expires_at do
			  label 'Invitation Expires At'
			  visible do
			    status = bindings[:object].invitation_status
			    status == 'invited' || status == 're-invited'
				end
				formatted_value do
					unless value.nil?
						distance = distance_of_time_in_words(value, DateTime.now)
						in_future = value > DateTime.now
						"#{value.to_s} - #{in_future ? 'in ' : ''}#{distance}#{in_future ? '' : ' ago'}"
					end
				end
			end
			include_fields :invited_by, :application_data, :created_at, :updated_at
		end
	end
end
