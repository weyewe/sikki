class GroupLoanBacklog < ActiveRecord::Base
  attr_accessible :group_loan_membership_id, :group_loan_weekly_responsibility_id, :group_loan_id
  belongs_to :group_loan_membership
  belongs_to :group_loan 
  
  belongs_to :backlog_clearance_source, :polymorphic => true 
  
  
end
