# porting group_loan_voluntary_savings => savings_account 
class GroupLoanPortVoluntarySavings < ActiveRecord::Base
  attr_accessible :group_loan_membership_id 
  has_many :savings_entries, :as => :savings_source 
  
  validates_uniqueness_of :group_loan_membership_id 
  
  after_create   :create_savings_entries 
  
  
  # no transaction.. only internal change 
  
  def create_savings_entries
    # withdrawing the compulsory savings
    total_voluntary_savings = self.group_loan_membership.total_voluntary_savings
    
    SavingsEntry.create_group_loan_voluntary_savings_withdrawal( self, total_voluntary_savings)     
    SavingsEntry.create_savings_account_addition( self, total_voluntary_savings)        
  end
end
