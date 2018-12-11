require "rails_helper"

RSpec.describe PermissionType do
  it "has a valid factory" do
    expect(build(:permission_type)).to be_valid
  end

  it { is_expected.to have_many(:user_permissions) }
  it { is_expected.to have_many(:application_permissions) }
  it { is_expected.to belong_to(:oauth_application) }

  it "is invalid without an oauth application" do
    expect(build(:permission_type, oauth_application: nil)).to be_invalid
  end

  it "is named with its oauth application's name and its code" do
    permission_type = build(:permission_type, application: "MDMS", code: "ABC")
    expect(permission_type.name).to eq "MDMS - ABC"
  end

  describe "identifying permission types related to customer portal" do
    context "when the type's oauth application's name is not MDMS" do
      it "does not return any permission types" do
        create(:permission_type, code: "OA_PAYER", application: "DEFINITELY_NOT_MDMS")

        expect(PermissionType.customer_portal).to be_empty
      end
    end

    context "when the type's oauth application's name is MDMS" do
      cp_codes = %w(OA_SHIPTO OA_PAYER OA_SOLDTO OA_ADMIN OA_BMG OA_CSB OA_ASM AD_SHIPTO AD_PAYER AD_SOLDTO PR_SHIPTO PR_PAYER PR_SOLDTO)

      cp_codes.each do |code|
        it "considers permission types with code #{code} to be for customer portal" do
          permission_type = create(:permission_type, code: code, application: "MDMS")
          expect(PermissionType.customer_portal).to include permission_type
        end
      end

      it "does not cosider permission types with other codes to be for customer portal" do
        permission_type = create(:permission_type, code: "OTHER_CODE", application: "MDMS")
        expect(PermissionType.customer_portal).to_not include permission_type
      end
    end
  end
end
