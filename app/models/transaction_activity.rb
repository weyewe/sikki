=begin
Cash_Direction          Savings_Direction       What does it mean? 
 incoming                 incoming                No Such Case   (NA)
 outgoing                 outgoing                Savings Withdrawal, cash going out, savings is deducted 
 incoming                 outgoing                Payment using combination of cash and savings withdrawal
 outgoing                 incoming                No such case 

=end

class TransactionActivity < ActiveRecord::Base
  attr_accessible :transaction_source_id, 
                  :transaction_source_type,
                  :cash,
                  :cash_direction,
                  :savings_direction, 
                  :savings, 
                  :member_id, 
                  :office_id
                  
  belongs_to :transaction_source, :polymorphic => true 
end

