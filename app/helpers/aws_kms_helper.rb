module AwsKmsHelper
	def self.decrypt(ciphertext)
		resp = client.decrypt(ciphertext_blob: ciphertext, encryption_context: encryption_context)
		resp.plaintext
	end

	def self.generate_data_key
		resp = client.generate_data_key(key_id: ENV['AWS_KMS_KEY_ID'], key_spec: 'AES_256', encryption_context: encryption_context)
		resp#.ciphertext_blob
	end

	def self.decrypt_env(key)
		memory_store.cleanup
		memory_store.fetch(key, expires_in: 5.minutes) do
			decrypt(Base64.strict_decode64(ENV[key]))
		end
	end

	private
	def self.encryption_context
		{'app' => 'UMS'}
	end
	def self.client
		Aws::KMS::Client.new(region: ENV['AWS_KMS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
	end
	def self.memory_store
		@@memory_store ||= ActiveSupport::Cache::MemoryStore.new
	end
end