class GroupLoanDefaultPayment < ActiveRecord::Base
  # attr_accessible :title, :body
  has_one :transaction_activity, :as => :transaction_source 
end
