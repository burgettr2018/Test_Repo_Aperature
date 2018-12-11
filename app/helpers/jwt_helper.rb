module JwtHelper
	def self.encode(payload)
		exp = (Time.now + 20.minutes).to_i

		JWT.encode payload.merge({exp: exp}), key, 'HS256'
	end
	def self.decode(jwt)
		token = "#{JWT.encoded_header('HS256')}.#{jwt}"
		leeway = 30 # seconds
		JWT.decode(token, key, true, { :exp_leeway => leeway, :algorithm => 'HS256' }).first
	end

	def self.from_access_token(token)
		unless token.resource_owner_id.blank?
			user = User.find(token.resource_owner_id)
			if user
				sub_payload = { :sub => user.id, :email => user.email, :given_name => user.first_name, :family_name => user.last_name, :token => token.id }

				token = JwtHelper.encode(sub_payload)
				headless_token = token.split('.')[1..-1].join('.')
				headless_token
			end
		end
	end

	private
	def self.key
		Base64.strict_encode64(ENV['DECRYPTED_JWT_KEY'] || AwsKmsHelper.decrypt_env('ENCRYPTED_JWT_KEY'))
	end
end