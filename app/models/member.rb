class Member < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  
  has_many :group_loans, :through => :group_loan_memberships 
  has_many :group_loan_memberhips 
  
  has_many :saving_entries 
  
  def update_total_savings_account
    incoming = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:savings_account],
      :direction => FUND_DIRECTION[:incoming]
    ).sum("amount")   
    
    outgoing = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:savings_account],
    ).sum("amount")
    
    self.total_savings_account  = incoming - outgoing 
    self.save
  end
end
