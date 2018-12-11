require "rails_helper"

RSpec.describe User do
  it { is_expected.to have_many(:user_permissions) }
  it { is_expected.to have_many(:permission_types).through(:user_permissions) }
  it { is_expected.to have_many(:oauth_applications).through(:permission_types) }
  it { is_expected.to have_many(:user_applications) }
  it { is_expected.to belong_to(:created_by).class_name(User) }
  it { is_expected.to have_many(:children).class_name(User) }
  it { is_expected.to have_many(:invitations).class_name(UserApplication) }

	describe "normalize_param_hash" do
		it "moves extra attributes into 'application_data'" do
			normalized = User.normalize_param_hash({
        email: 'toot@doot.com',
				guid: SecureRandom.uuid,
				some_extra_thing: 'data'
      }, nil, create(:oauth_application))
			expect(normalized).to include(
        application_data: {
						some_extra_thing: 'data'
				}
			)
			expect(normalized.keys).not_to include(:some_extra_thing, :guid)
		end
	end
end
