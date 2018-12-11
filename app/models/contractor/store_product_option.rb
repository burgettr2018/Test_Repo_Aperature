class Contractor::StoreProductOption < Contractor::ContractorBase
  self.table_name = 'contractor_store_product_options'
  belongs_to :product, class_name: 'Contractor::StoreProduct', foreign_key: 'contractor_store_product_id', inverse_of: :options
end
