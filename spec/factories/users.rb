FactoryBot.define do
  factory :user_no_associations, class: User do
    first_name { 'John' }
    password { 'password1!' }
    sequence(:last_name, 1000) { |n| "Smith #{n}" }
    sequence(:email, 1000) { |n| "person#{n}@example.com" }
		created_by_id { nil }
		guid { SecureRandom.uuid }

    factory :user do
      transient do
        sequence(:application) { |n| "BetterApplication-#{n}" }
        permissions {[{application: application, code: 'TEST1'}, {application: application, code: 'TEST2'}, {application: application, code: 'TEST3'}, {application: application, code: 'TEST4'}]}
        # need to store raw+enc values for unit tests
        invitation_token_pair { nil }
        invitation_token { nil }
        invitation_token_raw { nil }
        first_invitation_sent_at { nil }
				invitation_status { nil }
        current_invitation_sent_at { nil }
        invitation_expires_in { nil }
        application_data { nil }
      end

  		after(:create) do |user, evaluator|
				application_name = OauthApplication === evaluator.application ? evaluator.application.name : evaluator.application
  			ua = create(:user_application,
  						 application: application_name,
  						 user: user,
  						 invited_by_id: evaluator.created_by_id,
  						 first_invitation_sent_at: evaluator.first_invitation_sent_at,
  						 current_invitation_sent_at: evaluator.current_invitation_sent_at,
  						 invitation_expires_in: evaluator.invitation_expires_in,
							 invitation_status: evaluator.invitation_status || (evaluator.permissions.any? ? (evaluator.invitation_token.present? ? 'invited' : 'complete') : 'inactive'),
  						 invitation_token: evaluator.invitation_token,
							 invitation_token_raw: evaluator.invitation_token_raw,
							 application_data: evaluator.application_data
  			)

  			evaluator.permissions.each do |p|
					p_application = p.kind_of?(String) ? application_name : p.try(:[], :application)
					p_application = OauthApplication === p_application ? p_application.name : p_application
  				create(:user_permission, {
  				  :application => p.kind_of?(String) ? application_name : (p_application||application_name),
  				  :code        => p.kind_of?(String) ? p : p[:code],
						:value			 => p.kind_of?(String) ? '*' : (p[:value] || '*'),
  				  :user        => user
          })
  			end
  		end

  		trait :with_invitation_token do
  			invitation_token_pair {
					Devise.token_generator.generate(UserApplication, :invitation_token)
				}
				invitation_token {
					invitation_token_pair.second
				}
				invitation_token_raw {
					invitation_token_pair.first
				}
				first_invitation_sent_at { 10.days.ago }
  			current_invitation_sent_at { first_invitation_sent_at }
  		end

  		trait :with_expired_invitation do
  			invitation_expires_in { 1.day }
				invitation_status { "expired" }
  			with_invitation_token
  		end

      trait :with_future_invitation do
  			invitation_expires_in { 20.days }
  			with_invitation_token
  		end

      trait :with_future_reinvitation do
  			with_expired_invitation
  			current_invitation_sent_at { 1.day.ago }
  		end
  	end
  end
end
