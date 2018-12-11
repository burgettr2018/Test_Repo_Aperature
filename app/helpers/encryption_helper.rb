module EncryptionHelper
	def self.encrypt_3des_cbc_sha1(str, key)
		raise 'input value not provided' if str.blank?
		cipher = OpenSSL::Cipher.new('des-ede3-cbc')
		cipher.encrypt
		cipher.key = pad_hash(Digest::SHA1.digest(key.encode('UTF-16LE')), 24)
		cipher.iv = pad_hash(Digest::SHA1.digest(''.encode('UTF-16LE')), 8)
		cipher.update(str.encode('UTF-16LE')) + cipher.final
	end
	def self.encrypt_aes256_cbc_pkcs5_base64(str, key)
		cipher = OpenSSL::Cipher::AES256.new(:CBC)
		cipher.encrypt
		cipher.key = key
		iv = cipher.random_iv
		cipher.iv = iv

		# encrypt the data!
		encrypted = '' << iv << cipher.update(str) << cipher.final
		Base64.strict_encode64 encrypted
	end
	def self.encrypt_3des_ecb_md5(str, key)
		raise 'input value not provided' if str.blank?
		cipher = OpenSSL::Cipher.new('des-ede')
		cipher.encrypt
		cipher.key = Digest::MD5.digest(key.encode('UTF-16LE'))
		cipher.update(str.encode('UTF-16LE')) + cipher.final
	end
	def self.encrypt_3des_cbc_sha1_base64(str, key)
		Base64.strict_encode64 encrypt_3des_cbc_sha1(str, key)
	end
	def self.decrypt_3des_cbc_sha1(str, key)
		raise 'input value not provided' if str.blank?
		cipher = OpenSSL::Cipher.new('des-ede3-cbc')
		cipher.decrypt
		cipher.key = pad_hash(Digest::SHA1.digest(key.encode('UTF-16LE')), 24)
		cipher.iv = pad_hash(Digest::SHA1.digest(''.encode('UTF-16LE')), 8)
		(cipher.update(str) + cipher.final).force_encoding('UTF-16LE').encode('UTF-8')
	end
	def self.decrypt_3des_cbc_sha1_base64(str, key)
		decrypt_3des_cbc_sha1(Base64.strict_decode64(str), key)
	end
	def self.pad_hash(str, length)
		bytes = str.bytes
		if bytes.length < length
			bytes = bytes + Array.new(length - bytes.length, 0)
		elsif bytes.length > length
			bytes = bytes[0..length-1]
		end
		bytes.pack('c*')
	end
end
