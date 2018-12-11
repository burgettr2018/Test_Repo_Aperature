class BaseSerializer < ActiveModel::Serializer
	def serializable_hash(adapter_options = nil, options = {}, adapter_instance = self.class.serialization_adapter_instance)
		if serialization_context.try(:[], :snakecase).to_b
			super
		else
			super.deep_transform_keys{
					|k|
				k.to_s.camelize(:lower)
			}
		end
	end

	# helpers since derived classes may get cameled/snaked keys in hash
	def is_key?(key, sym)
		key.to_s == sym.to_s || key.to_s == sym.to_s.camelize(:lower)
	end
	def is_key_one_of?(key, syms)
		syms.select{|s| is_key?(key, s)}.any?
	end
end