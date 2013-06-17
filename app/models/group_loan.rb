class GroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :members, :through => :members 
  has_many :group_loan_memberships 
  has_many :sub_group_loans 
  
  has_many :group_loan_weekly_tasks # weekly payment, weekly attendance  
  
end