class SubGroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :group_loan 
  has_many :group_loan_memberships 
end
