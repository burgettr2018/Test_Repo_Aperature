Owenscorning::WebCommon.setup do |config|
	# The OAuth application name from Owens Corning UMS
	# For resources that require authenticated access without any particular permission/value, the user will
	# be granted access to the resource if they have any permission for this application
	config.application_name = 'UMS'

	# The OAuth application client id (Uid) from Owens Corning UMS
	config.client_id = ''
	# The OAuth application client secret from Owens Corning UMS
	config.client_secret = ''

	# The Owens Corning UMS instance appropriate for this environment (https://login.owenscorning.com, etc.)
	config.ums_host = ENV['UMS_OC_OAUTH_HOST']

	# The Owens Corning MDMS instance appropriate for this environment (https://mdms.owenscorning.com, etc.)
	config.mdms_host = ENV['MDMS_URL']

	# The Owens Corning Maplesyrup instance appropriate for this environment (https://mdms-stage.owenscorning.com/prod, etc.)
	config.maplesyrup_host = 'https://mdms-stage.owenscorning.com/prod'

	# Configure/add status checks
	# In-built status checks are ActiveRecordCheck, CacheCheck, PingCheck, WheneverCheck
	# PingCheck accepts a hash parameter :pings which is a hash of key->url to test, e.g.
	# config.add_status_check(Owenscorning::WebCommon::Status::Checks::PingCheck, :pings => {
	# 		:solr => "http://#{Sunspot::Rails.configuration.hostname}:#{Sunspot::Rails.configuration.port}/"
	# })
	# checks only need to respond to "call" (see https://github.com/envylabs/rapporteur) and the params hash keys
	# are applied if respond_to them

	# error reporting, these are default:
	# config.errbit_host = 'errbit.owenscorning.com'
	# config.errbit_js_host = 'https://errbit.owenscorning.com'
	# config.errbit_env = Rails.env
	# this must be set per site:
	config.errbit_api_key = 'b1532a97310fc6960c1afbbf31e51c5a'
	config.errbit_env = ENV['ERRBIT_ENV'] || Rails.env
	config.errbit_host = ENV['ERRBIT_HOST'] || 'errbit.owenscorning.com'

	config.skip_helpers = true
	config.skip_middleware = true
end

# extra monkey patching for UMS
module Owenscorning
  module WebCommon
    module UmsLogin
			def self.get_application_token
				Rails.cache.fetch("oauth_token", expires_in: 5.minutes) do
					Doorkeeper::AccessToken.find_or_create_for(OauthApplication.find_by_name('UMS'), nil, 'public', 2.hours, false).token
				end
			end
		end
	end
end
