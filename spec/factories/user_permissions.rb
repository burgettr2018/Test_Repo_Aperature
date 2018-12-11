FactoryBot.define do
  factory :user_permission do
    transient do
      sequence(:application, 100) { |n| "SomeApplication-#{n}" }
      sequence(:code, 100) { |n| "PERMISSION_#{n}" }
    end

    value { '*' }
    user
    permission_type { create(:permission_type, application: application, code: code) }

    factory :customer_portal_user_permission do
      transient do
        application { "MDMS" }
        code { "OA_PAYER" }
      end
    end
  end
end
