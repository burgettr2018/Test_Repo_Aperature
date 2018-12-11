class Api::V1::ApiController < ActionController::Base
  attr_accessor :current_user, :current_application

  include Pundit
  include ApiParametersHelper

  serialization_scope :serialization_context
  def serialization_context
    begin
      { root: false, snakecase: is_snakecase_params, current_application: self.current_application, current_user: @current_user, params: params }
    rescue
      { root: false, snakecase: is_snakecase_params, current_application: @current_application, current_user: @current_user, params: params }
    end
  end


  before_action  :load_user

  respond_to :json

  rescue_from Exception, with: :error
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
  rescue_from Pundit::NotAuthorizedError, with: :no_access

  def index
    render json:{ :ok => true }
  end

  def api_context_log(string)
    api_log = request.env['api_log']
    if api_log.present?
      context_hash = api_log.context_hash || {}
      context_hash[:log] ||= []
      context_hash[:log] << string
			api_log.context_hash = context_hash
    else
      Rails.logger.info(string)
    end
  end

  def api_context_object(hash)
    api_log = request.env['api_log']
    if api_log.present?
      context_hash = api_log.context_hash || {}
      context_hash.merge!(hash)
      api_log.context_hash = context_hash
    else
      Rails.logger.info(hash.to_s)
    end
  end

  private

  #http://www.javiersaldana.com/2013/04/29/pagination-with-activeresource.html
  def self.set_headers(options = {})
    after_filter(options) do |controller|
      results = instance_variable_get("@#{controller_name}")
      results = instance_variable_get("@#{controller_name.to_s.pluralize}") if results.blank?
      results = instance_variable_get("@collection") if results.blank?
      if results
        headers["pagination-limit"] = results.limit_value.to_s
        headers["pagination-offset"] = results.offset_value.to_s
        headers["pagination-total"] = results.total_count.to_s
      end
    end
  end

  def doorkeeper_unauthorized_render_options(error: nil)
    response.headers["WWW-Authenticate"] = 'OAuth,Basic'
    { json: { error: 'You are not authorized to perform this action.' } }
  end

  def load_user
    doorkeeper_authorize!
    dk_token = doorkeeper_token

    if !dk_token.nil?
      application = OauthApplication.find(dk_token.application.try(:id))
      self.current_application = application
      if dk_token.resource_owner_id.blank?
        self.current_user = application
      else
        self.current_user = User.find(dk_token.resource_owner_id)
      end
    end
    @current_user = self.current_user
    @current_application = application
  end

  # Find the user that owns the access token
  def current_resource_owner
    User.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  def error(error)
    logger.error "Error during processing: #{$!}"
    logger.error "Backtrace:\n\t#{error.backtrace.join("\n\t")}"
    notify_airbrake(error)
    render json: {error:'An error occurred.'}, status: 500
  end
  def no_access
    render json: {error:'You are not authorized to perform this action.'}, status: 401
  end
  def forbidden
    render json: {error:'You are not authorized to perform this action.'}, status: 403
  end
  def not_found
    render json: {error:'Not found.'}, status: 404
  end
  def invalid_record(invalid)
    render json: {errors: invalid.record.errors}, status: 400
  end

end
