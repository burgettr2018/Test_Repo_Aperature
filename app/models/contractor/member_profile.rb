class Contractor::MemberProfile < Contractor::ContractorBase
	self.table_name = 'contractor_member_profiles'

	belongs_to :contractor_pqs_profile, class_name: 'Contractor::PqsProfile', primary_key: 'membership_number', foreign_key: 'membership_number'
	rails_admin do
		list do
			configure :contractor_pqs_profile do
				hide
			end
			configure :membership_number do
				show
				filterable true
				searchable true
			end
			include_fields :id, :membership_number, :company_name, :membership_status, :membership_hierarchy, :loyalty_program_code, :tier_level, :web_visible, :company_zip, :account, :location
		end
		show do
			configure :membership_number do
				show
			end
		end
	end

	def self.for_program(loyalty_program_code)
		where('lower(loyalty_program_code) = ?', loyalty_program_code.try(:downcase))
	end
	def self.for_location(location)
		where('lower(location) = ?', location.try(:downcase))
	end
	def self.for_number(number)
		where('lower(membership_number) = ?', (number||'').downcase)
	end
	def self.like_number(number)
		where('membership_number ilike ?', "#{(number||'').downcase}%")
	end
	def self.for_funds
		where('multi_location_account = ? or (lower(membership_hierarchy) = lower(who_can_redeem_rewards))', false)
	end
	def self.for_status(status)
		if String===status
			where('lower(membership_status) = ?', status.try(:downcase))
		else
			where("lower(membership_status) #{status.to_b ? '=' : '<>'} ?", 'active')
		end
	end
	def self.for_account(account)
		where('lower(account) = ?', account.try(:downcase))
	end
	def self.for_hierarchy(hier)
		where('lower(membership_hierarchy) = ?', hier.try(:downcase))
	end

	def self.location_guid_by_member_id(member_id)
		where(membership_number: member_id).first.try(:location)
	end

	def users
		# opposite function of mdms memberprofile "for_user"
		# doesn't filter for active users though
		account = self.account
		location = self.location
		users_for_account = User.for_permission_and_value('CONTRACTOR_PORTAL', 'ACCOUNT', account)
		users_for_location = User.for_permission_and_value('CONTRACTOR_PORTAL', 'LOCATION', location)
		global_users_for_account = User.for_permission_and_value('CONTRACTOR_PORTAL', 'LEVEL', 'global').where(id: users_for_account.pluck(:id))
		location_users_for_account = User.for_permission_and_value('CONTRACTOR_PORTAL', 'LEVEL', 'location').where(id: users_for_location.pluck(:id))
		User.where(id: global_users_for_account.pluck(:id) + location_users_for_account.pluck(:id))
	end
end
