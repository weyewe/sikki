class GroupLoanMembership < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office
  belongs_to :member 
  belongs_to :group_loan 
  belongs_to :sub_group_loan 
  
  has_one :group_loan_default_payment  #checked  
  has_one :group_loan_disbursement  #checked 
  has_many :group_loan_weekly_payments   # we need the model. A weekly task 
  # => can be paid through backlog payment, weekly payment, or independent payment 
  has_many :group_loan_independent_payments
  has_many :group_loan_grace_payments
  has_many :group_loan_weekly_responsibilities
end
