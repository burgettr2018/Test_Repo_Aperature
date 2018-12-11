class Contractor::StoreProduct < Contractor::ContractorBase
  self.table_name = 'contractor_store_products'

  belongs_to :vendor, class_name: 'Contractor::StoreVendor', foreign_key: 'contractor_store_vendor_id'
  has_many :options, class_name: 'Contractor::StoreProductOption', foreign_key: 'contractor_store_product_id', inverse_of: :product, dependent: :destroy
end
