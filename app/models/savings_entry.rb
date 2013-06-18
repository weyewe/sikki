# this is the backbone to track savings, any kind of savings
# group_loan_compulsory_savings, group_loan_voluntary_savings 
# normal_savings_account (with interest monthly)
# and even savings withdrawal

class SavingsEntry < ActiveRecord::Base
  attr_accessible :savings_source_id, 
                  :savings_source_type,
                  :amount,
                  :savings_status,
                  :direction,
                  
                  :financial_product_id,
                  :financial_product_type 
                  
  belongs_to :savings_source, :polymorphic => true
  belongs_to :financial_product, :polymorphic => true 
end
