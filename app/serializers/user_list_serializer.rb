class UserListSerializer < BaseSerializer
	attributes :meta, :users

	def users
		object.to_a.map{
				|p|
			UserSerializer.new(p, root: false, scope: serialization_context, scope_name: :serialization_context)
		}
	end
	def meta
		meta = {
				page: object.current_page,
				item_count: object.limit_value,
				total: object.total_count
		}
		meta.merge!({query: serialization_context[:params][:q]}) if serialization_context[:params][:q].present?
		meta
	end
end