class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  include Pundit
  protect_from_forgery with: :exception

  before_filter :feature_user_cookie
  before_filter :feature_querystring_group

  before_action :set_redirect
  before_action :set_locale
  before_action :set_referer_application
  after_action :verify_authorized, :except => :index , unless: :no_authorized_policy
  after_action :verify_policy_scoped, :only => :index, unless: :no_scope_policy


  before_action if: Proc.new {ENV['UMS_ERRBIT_REQUEST'].to_b} do
    notify_airbrake "pre request"
    end
  after_action if: Proc.new {ENV['UMS_ERRBIT_REQUEST'].to_b} do
    notify_airbrake "post request"
  end

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :configure_permitted_parameters, if: :devise_controller?

  # def pundit_user
  #   raise Pundit::NotAuthorizedError, "must be logged in" unless current_user
  #   company = current_user.companies.first if current_user.companies
  #   UserContext.new(current_user, company)
  # end

  def after_sign_out_path_for(resource_or_scope)
    ret=session[:return_to] || session[:return_url] || scrub_referrer_return_path_for_logout || root_path
    session.delete(:return_to)
    session.delete(:return_url)
    ret
  end

  def after_update_path_for(resource_or_scope)
    ret=session[:return_to] || session[:return_url] || root_path
    session.delete(:return_to)
    session.delete(:return_url)
    ret
  end

  def after_sign_in_path_for(resource)
    user = resource || current_user
    if (user.is_database_provider) && (user.last_password_change_at.to_i == user.created_at.to_i)
      ret = edit_password_only_path
    elsif user.is_exclusive_customer_portal_user && !user.is_okta_user
      ret = OauthApplication.find_by_name('CUSTOMER_PORTAL').try(:application_uri)
    else
      ret = session[:return_to] || root_path
    end
    session[:return_to] = nil

    return ret
  end

  def feature_user_cookie
    if session[:flipper_id].blank?
      session[:flipper_id] = SecureRandom.uuid
    end
  end

  def feature_querystring_group
    user = Feature::User.from_session(session)
    if !params[:enable].blank?
      if params[:enable].kind_of?(Array)
        params[:enable].each do |feature|
          enable_feature feature, user
        end
      else
        enable_feature params[:enable], user
      end
    end
    if !params[:disable].blank?
      if params[:disable].kind_of?(Array)
        params[:disable].each do |feature|
          disable_feature feature, user
        end
      else
        disable_feature params[:disable], user
      end
    end
  end

  private

  def scrub_referrer_return_path_for_logout
    request.referrer =~ /\/users\/sign_out\/?$\Z/ ? nil : request.referrer
  end

  def set_redirect
    if !params[:return_to].blank?
      session[:return_to] = params[:return_to]
    end
  end

  def acceptable_langs(collection)
    collection.each do |language|
      if language.include? "_"
        language_segments = language.split("_")
        language_segments.last.capitalize!
        hyphenated_langauge = language_segments.join('-')
        match = I18n.available_locales.select {|lang_code| lang_code == hyphenated_langauge.to_sym}

        if !match.empty?
          return match
          break
        end
      end

      langs = collection.map{|l| l.split('_').first.to_sym}.uniq
      match = langs & I18n.available_locales
      return match
    end
  end

  def set_locale
    language = params[:lang] || cookies.try(:[], :lang) || request.env['HTTP_ACCEPT_LANGUAGE']
    language_collection = language.try(:split, ',') || []
    underscored_language_collection = language_collection.map{|l| l.split(';').first.underscore}

    preferred_lang = acceptable_langs(underscored_language_collection).first
    if preferred_lang.present?
      cookies[:lang] = {
          value: preferred_lang,
          expires: 1.year.from_now,
          domain: Rails.env.development? ? 'localhost' : '.owenscorning.com'
      } if params[:lang].present?
      I18n.locale = preferred_lang
    else
      I18n.locale = I18n.default_locale
    end
    @language = I18n.locale.to_s
  end

  def no_scope_policy
    return controller_name == 'home'|| devise_controller? || controller_name == 'main'
  end

  def no_authorized_policy
    return controller_name == 'home' || devise_controller? || controller_name == 'main' || controller_name == 'o_data'
  end

  def user_not_authorized
    return redirect_to new_user_session_path if current_user.blank?
    flash[:error] = t('errors.not_authorized')
    redirect_to(request.referrer || root_path)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :first_name,:last_name, :email, :password, :password_confirmation, :current_password) }
  end

  def set_referer_application
    referer ||= (cookies[:sign_in_referer] || session[:return_to] || request.referer || '')

    if referer.include? 'fatout'
      @referer_application = 'FatOut'
    elsif referer.include? 'cpi'
      @referer_application = 'Competitive Pricing Inventory'
    elsif referer.include? 'installed-services'
      @referer_application = 'Lowe\'s Installed Services'
    elsif referer.include? 'customerportal'
      @referer_application = 'Customer Portal'
    elsif referer.include? 'ccd'
      @referer_application = 'Okta-requiring Application'
    end
  end

  def enable_feature(feature, user)
    featureToggle = Feature.flipper[feature]
    if !featureToggle.enabled? user
      featureToggle.enable user
    end
  end

  def disable_feature(feature, user)
    featureToggle = Feature.flipper[feature]
    if featureToggle.enabled? user
      featureToggle.disable user
    end
  end

  def update_devise_log
    if !current_user.nil?
      current_user.devise_log_histories.create(
        devise_action: (params[:controller] == "passwords" ? "password_changed" : "signed_in"),
        date: Time.current,
        ip_address: request.remote_ip
      )
    end
  end
end
