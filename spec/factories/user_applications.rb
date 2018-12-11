FactoryBot.define do
  factory :user_application do
    transient do
      sequence(:application) { |n| "AnotherApplication-#{n}" }
    end

    oauth_application {create(:oauth_application, name: application)}
    user
  end
end
