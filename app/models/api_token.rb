class ApiToken < ActiveRecord::Base
	belongs_to :access_token, class_name: 'Doorkeeper::AccessToken', dependent: :destroy
	belongs_to :user
	has_one :application, through: :access_token, class_name: 'OauthApplication'
	validates :access_token, presence: true
	validates :note, presence: true

	before_destroy :revoke_access_token

	def revoke_access_token
		access_token.revoke if access_token
	end

	def uid
		application.uid
	end
	def secret
		application.secret
	end
	def token
		access_token.token
	end
	def expires_at
		access_token.created_at + access_token.expires_in if access_token.present?
	end
	def application=(val)
		self.access_token = Doorkeeper::AccessToken.find_or_create_for(val, nil, 'public', 2.hours, false)
	end
	def expires_at=(val)
		self.access_token.update_attributes(expires_in: val-Time.current)
	end

	#attr_accessible :application_id
	def application_id
		self.application.try :id
	end
	def application_id=(id)
		self.application = OauthApplication.find_by_id(id)
	end

	def custom_label_method
		"#{application.try(:name)} - #{note}"
	end

	rails_admin do
		navigation_label 'APIs'
		weight -1
		label 'API Tokens'
		object_label_method do
			:custom_label_method
		end
		list do
			include_fields :application, :note
			field :expires_at do
				formatted_value do
					unless value.nil?
						value.strftime('%Y-%m-%d')
					end
				end
			end
			include_fields :user
		end
		create do
			include_fields :application, :note
			field :expires_at, :datetime do
				help 'Required'
				formatted_value do
					'nil'
				end
				def value
					Time.current + 1.year
				end
			end
			field :user_id, :hidden do
				help 'Required'
				visible true
				default_value do
					bindings[:controller].current_user.id
				end
			end
		end
		show do
			include_fields :application, :note
			field :token
			field :expires_at do
				formatted_value do
					unless value.nil?
						distance = distance_of_time_in_words(value, DateTime.now)
						in_future = value > DateTime.now
						"#{value.to_s} - #{in_future ? 'in ' : ''}#{distance}#{in_future ? '' : ' ago'}"
					end
				end
			end
			include_fields :user
		end
	end
end