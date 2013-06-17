class TransactionActivity < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :transaction_source, :polymorphic => true 
end

