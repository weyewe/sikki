# it will port group_loan compulsory savings => group_loan voluntary savings at the end of the period 
class GroupLoanPortCompulsorySavings < ActiveRecord::Base
  attr_accessible :group_loan_membership_id 
  has_many :savings_entries, :as => :savings_source 
  
  validates_uniqueness_of :group_loan_membership_id 
  
  after_create   :create_savings_entries
  
  
  # no transaction.. only internal change 
  
  def create_savings_entries
    # withdrawing the compulsory savings
    total_compulsory_savings = self.group_loan_membership.total_compulsory_savings 
     
    SavingsEntry.create_group_loan_compulsory_savings_withdrawal( self, total_compulsory_savings )
    SavingsEntry.create_group_loan_voluntary_savings_addition( self, total_compulsory_savings)
  end
  
end
