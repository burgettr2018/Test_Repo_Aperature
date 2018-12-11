require "rails_helper"

RSpec.describe UserPermission do
  it "has a valid factory" do
    expect(build(:user_permission)).to be_valid
  end

  it "is invalid without a user" do
    expect(build(:user_permission, user: nil)).to be_invalid
  end

  it "is invalid without a permission type" do
    expect(build(:user_permission, permission_type: nil)).to be_invalid
  end
end
