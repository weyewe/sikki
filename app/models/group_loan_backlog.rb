class GroupLoanBacklog < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :group_loan_membership
  belongs_to :group_loan 
end
