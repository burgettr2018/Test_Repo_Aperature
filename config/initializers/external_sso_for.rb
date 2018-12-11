module ActionDispatch::Routing
	class Mapper
		def external_sso_for(token)
			Rails.application.routes.draw do
				devise_scope :user do
					get "/users/#{token}/sso" => "sessions##{token}"
					get "/users/#{token}/sso/:location" => "sessions##{token}", as: "#{token}_sso"
					get "/users/#{token}/sso/:location/:to" => "sessions##{token}", constraints: { to: /.+/ }
				end
			end
		end
	end
end