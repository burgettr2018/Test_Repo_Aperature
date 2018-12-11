class Contractor::StoreOrder < Contractor::ContractorBase
  self.table_name = 'contractor_store_orders'

  belongs_to :member_profile, class_name: 'Contractor::MemberProfile', foreign_key: :member_profile_id
  belongs_to :funds_usage, class_name: 'Contractor::MemberProfileFundsUsage', foreign_key: :contractor_member_profile_funds_usage_id
  has_many :order_items, class_name: 'Contractor::StoreOrderItem', foreign_key: :contractor_store_order_id, inverse_of: :order, dependent: :destroy

  rails_admin do
    parent Contractor::MemberProfile
    label 'Order'
    list do
      exclude_fields :order_items
    end
  end
end
