class HomeController < ApplicationController
  def index
    if current_user.blank?
      return redirect_to "/users/sign_in"
    end

    @links = []
    current_user.oauth_applications.uniq.each{
        |a|
      if a.name == 'CONTRACTOR_PORTAL'
        # if they have any permission other than "IMPERSONATE" then the portal is an option
        if current_user.user_permissions.joins(:permission_type).where(permission_types: {oauth_application_id: a.id}).where.not(permission_types: {code: 'IMPERSONATE'}).any?
          @links << [a.application_uri, a.proper_name]
        end
        if current_user.has_permission?('CONTRACTOR_PORTAL', 'IMPERSONATE')
          @links << [users_impersonate_path, 'OCConnect™ - Impersonate User']
        end
      elsif a.name == 'MDMS' || a.name == 'CUSTOMER_PORTAL'
        if current_user.user_permissions.present? && current_user.user_permissions.any?{|p| p.is_customer_portal_permission}
          customer_portal_app = OauthApplication.find_by_name('CUSTOMER_PORTAL')
          if customer_portal_app.application_uri.present?
            @links << [customer_portal_app.application_uri, customer_portal_app.proper_name]
          end
        end
        if current_user.has_permission?('MDMS', 'CONTRACTORS_FUNDS_MANAGE')
          oc_com_app = OauthApplication.find_by_name('OC_COM')
          @links << [File.join(oc_com_app.application_uri, '/connect/payments/'), 'OCConnect™ - Credit Card or Promo Fund Payments']
        end
        if current_user.has_permission?('MDMS', 'CLAIM_REVIEW') || current_user.has_permission?('MDMS', 'CLAIM_VIEW')
          mdms_app = OauthApplication.find_by_name('MDMS')
          @links << [File.join(mdms_app.application_uri, '/admin/claims'), 'OCConnect™ - Invoice/Claim Review']
        end
        if current_user.has_permission?('MDMS', 'BLAZER')
          mdms_app = OauthApplication.find_by_name('MDMS')
          @links << [File.join(mdms_app.application_uri, '/blazer'), 'MDMS - Data Visualization (Blazer)']
        end
        if current_user.has_permission?('MDMS', 'BASEMENTS_ADMIN') || current_user.has_permission?('MDMS', 'PRODUCT_EDIT') || current_user.has_permission?('MDMS', 'PRODUCT_PUBLISH') || current_user.has_permission?('MDMS', 'RAILS_ADMIN')
          mdms_app = OauthApplication.find_by_name('MDMS')
          @links << [mdms_app.application_uri, 'MDMS']
        end
      else
        @links << [a.application_uri, a.proper_name]
      end
    }

    @links = @links.select{|l| l.first.present?}
    @links = @links.uniq

    if !current_user.admin && !current_user.has_permission?('UMS', 'USERS_MANAGE') && @links.count == 1
      redirect_to @links.first.first
    end

  end
end
