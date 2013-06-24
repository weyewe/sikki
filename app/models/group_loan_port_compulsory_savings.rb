# it will port group_loan compulsory savings => group_loan voluntary savings at the end of the period 
class GroupLoanPortCompulsorySavings < ActiveRecord::Base
  attr_accessible :group_loan_membership_id 
  has_many :transaction_activities, :as => :transaction_source 
  has_many :savings_entries, :as => :savings_source 
  
  validates_uniqueness_of :group_loan_membership_id 
  
  after_create   :create_savings_entries
  
  
  # no transaction.. only internal change 
  
  def create_savings_entries
    # withdrawing the compulsory savings
    SavingsEntry.create :savings_source_id => self.id,
                        :savings_source_type => self.class.to_s,
                        :amount => self.group_loan_membership.total_compulsory_savings ,
                        :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
                        :direction => FUND_DIRECTION[:outgoing],
                        :financial_product_id => self.group_loan_membership.group_loan_id ,
                        :financial_product_type => self.group_loan_membership.group_loan.to_s
                        
    # adding the savings at the voluntary savings
    SavingsEntry.create :savings_source_id => self.id,
                        :savings_source_type => self.class.to_s,
                        :amount =>self.group_loan_membership.total_compulsory_savings,
                        :savings_status => SAVINGS_STATUS[:group_loan_voluntary_savings],
                        :direction => FUND_DIRECTION[:incoming],
                        :financial_product_id => self.group_loan_membership.group_loan_id ,
                        :financial_product_type => self.group_loan_membership.group_loan.to_s 
  end
  
end
