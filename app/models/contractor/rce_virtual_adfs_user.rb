class Contractor::RceVirtualAdfsUser < ActiveRecord::Base
	RCE_VIRTUAL_USER_EMAIL_DOMAIN = ENV['UMS_RCE_VIRTUAL_USER_EMAIL_DOMAIN']

	belongs_to :user
	belongs_to :member_profile, class_name: 'Contractor::MemberProfile', primary_key: "location", foreign_key: "location_guid"

	belongs_to :estore_profile, class_name: 'Contractor::EstoreProfile', primary_key: :login_name, foreign_key: :email

	before_create :set_calculated_attributes
	after_commit :sync_to_adfs

	def set_calculated_attributes
		self.email = "#{user.guid}_#{self.location_guid}@#{RCE_VIRTUAL_USER_EMAIL_DOMAIN}"
		#re-use last username for this email or use a uniquish one from token
		self.username = TransactionalPortalHelper.get_ad_user_by_email(self.email).try(:[], :user_name) || loop do
			raw = "rce_#{Devise.friendly_token(16).downcase}"
			break raw unless self.class.to_adapter.find_first(username: raw) || TransactionalPortalHelper.get_ad_user(raw).present?
		end

		self.salt = Devise.friendly_token
	end

	def password
		strong_password = OpenSSL::HMAC.hexdigest('SHA256', OpenSSL::PKCS5.pbkdf2_hmac_sha1(Rails.application.secrets[:secret_key_base], 'pepper', 2**16, 64), self.salt)
		"a!#{strong_password[2,32]}"
	end

	def sync_to_adfs
		if destroyed?
			# we don't want to actually DELETE an AD user, we will lock them
			TransactionalPortalHelper.delay.disable_ad_user(username)
		else
			# we may already have the user if this is re-added for same guids, so we re-enable, else add, wrapped in a convenient helper
			Contractor::RceVirtualAdfsUser.delay.add_or_update(self.id)
		end
	end
	def self.add_or_update(record_id)
		record = where(id: record_id).first
		return if record.nil?

		TransactionalPortalHelper.add_or_enable_ad_user(record.username, record.email, record.user.first_name, record.user.last_name, record.password)
		record.update_columns(last_synced_to_adfs: DateTime.now.utc)
		#after added, get the username.  add_or_enable_user adds or re-enables by email as PK and might return a different username
		username = TransactionalPortalHelper.get_ad_user_by_email(record.email).try(:[], :user_name)
		if username != record.username
			#important! skip callbacks
			record.update_columns(username: username)
		end
	end

	rails_admin do
		parent Contractor::EstoreProfile
		label 'RCE Virtual ADFS Users'
		list do
			include_fields :id, :user, :member_profile, :email, :username, :last_synced_to_adfs, :created_at, :updated_at
		end
		show do
			configure :email do
				show
			end
			configure :estore_profile do
				show
			end
		end
	end
end
