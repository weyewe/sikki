class Member < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  
  has_many :group_loans, :through => :group_loan_memberships 
  has_many :group_loan_memberhips 
end
