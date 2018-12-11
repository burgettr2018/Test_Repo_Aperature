FactoryBot.define do
  factory :permission_type do
    initialize_with {
      response = PermissionType.where(oauth_application_id: oauth_application.try(:id), code: code).first_or_initialize(attributes)
      response.assign_attributes(attributes) unless response.nil?
      response
    }

    transient do
      sequence(:application, 100) { |n| "ApplicationForPermissionType-#{n}" }
    end

    sequence(:code, 100) { |n| "PERMISSION_#{n}" }
    oauth_application { create(:oauth_application, name: application) }

    factory :customer_portal_permission_type do
      code { "OA_PAYER" }
      application { "MDMS" }
    end
  end
end
