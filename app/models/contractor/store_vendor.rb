class Contractor::StoreVendor < Contractor::ContractorBase
	self.table_name = 'contractor_store_vendors'
	has_many :products, class_name: 'Contractor::StoreProduct', foreign_key: 'contractor_store_vendor_id', inverse_of: :vendor
end
