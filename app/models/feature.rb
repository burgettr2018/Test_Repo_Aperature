require 'flipper'
require 'flipper/adapters/active_record'

class Feature
	@@adapter = Flipper::Adapters::ActiveRecord.new

	mattr_accessor :flipper
	@@flipper = Flipper.new(@@adapter)

	class User
		def initialize( id )
			@flipper_id = id
		end
		def flipper_id
			@flipper_id
		end
		def self.from_session(session)
			User.new(session[:flipper_id])
		end
	end
end
