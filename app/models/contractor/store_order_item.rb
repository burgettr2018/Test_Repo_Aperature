class Contractor::StoreOrderItem < Contractor::ContractorBase
	self.table_name = 'contractor_store_order_items'

  belongs_to :order, inverse_of: :order_items, class_name: 'Contractor::StoreOrder'
  belongs_to :product, foreign_key: 'contractor_store_product_id', class_name: 'Contractor::StoreProduct'
  belongs_to :product_option, foreign_key: 'contractor_store_product_option_id', class_name: 'Contractor::StoreProductOption'

	rails_admin do
		parent Contractor::StoreOrder
		label 'Order Item'
	end
end
