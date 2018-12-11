class ApiRequestLog < ActiveRecord::Base
    rails_admin do
        navigation_label 'APIs'
        label 'Incoming API Request Log'
        list do
          include_fields :status, :method, :oauth_application, :url, :time, :ip, :duration_ms
          limited_pagination true
        end
        show do
          include_fields :status, :method, :oauth_application, :url, :time, :ip, :query_params, :request_format, :raw_request_body, :parsed_request_body, :format, :response, :trace_id, :access_token, :duration_ms, :context_hash
          configure :api_token
        end
    end

    belongs_to :oauth_application

    def api_token
        if access_token
            Doorkeeper::AccessToken.where(token: access_token).first.api_token
        end
    end
end
