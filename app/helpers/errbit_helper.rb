module ErrbitHelper
	def self.notify_airbrake(hash)
		Rails.logger.debug hash
		if hash.kind_of?(Hash)
			Airbrake.notify_sync(hash[:error_message], hash.except(:error_message))
		else
			Airbrake.notify_sync(hash)
		end
	end
end