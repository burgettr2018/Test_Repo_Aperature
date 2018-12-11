module ApiParametersHelper
	def snakecase_params
		@old_params ||= params.deep_dup
		params.deep_transform_keys! {|k| k.to_s.underscore.to_sym }
		@camelcase = !(params == @old_params)
		params
	end
	def is_snakecase_params
		!@camelcase
	end
	def setup_json_serializer(json, *args)
		@serializer = Jbuilder::KeyFormatter.new(*args)
		@json ||= json
		@json.key_format! *args
	end
	def json_merge!(hash_or_array)
		if ::Hash === hash_or_array
			@json.merge! hash_or_array.deep_transform_keys! {
					|k|
				@serializer.format(k)
			}
		else
			@json.merge! hash_or_array
		end
	end
end