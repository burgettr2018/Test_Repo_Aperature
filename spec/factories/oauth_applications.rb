FactoryBot.define do
  factory :oauth_application do
    initialize_with {
      response = OauthApplication.where(name: name).first_or_initialize(attributes)
      response.assign_attributes(attributes) unless response.nil?
      response
    }

    sequence(:name) { |n| "Application-#{n}" }
    proper_name { name }
    redirect_uri { 'http://localhost:3000' }

    factory :ums do
      name { 'UMS' }
      after(:create) do |app, evaluator|
        app.permission_types << create(:permission_type, code:'USERS_MANAGE', oauth_application: app)
      end
    end

    trait :with_cross_app_permission_star do
      after(:create) do |app, evaluator|
        create(:application_permission, application: 'UMS', code: 'CROSS_APPLICATION_PERMISSIONS', oauth_application: app, value: '*')
      end
    end
    trait :with_user_manage_permission do
      after(:create) do |app, evaluator|
        create(:application_permission, application: 'UMS', code: 'USERS_MANAGE', oauth_application: app)
      end
    end
    trait :with_virtual_user_manage_permission do
      after(:create) do |app, evaluator|
        create(:application_permission, application: 'UMS', code: 'VIRTUAL_USERS_MANAGE', oauth_application: app)
      end
    end
    trait :with_invitation_period do
      after(:create) do |app, evaluator|
        app.invitation_expiry_days = 14
        app.save!
      end
    end
  end
end
