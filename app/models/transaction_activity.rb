class TransactionActivity < ActiveRecord::Base
  attr_accessible :transaction_source_id, 
                  :transaction_source_type,
                  :incoming_cash,
                  :incoming_savings 
                  
  belongs_to :transaction_source, :polymorphic => true 
end

