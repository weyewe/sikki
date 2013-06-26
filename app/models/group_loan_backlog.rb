class GroupLoanBacklog < ActiveRecord::Base
  attr_accessible :group_loan_membership_id, :group_loan_weekly_responsibility_id, :group_loan_id
  belongs_to :group_loan_membership
  belongs_to :group_loan 
  
  belongs_to :backlog_clearance_source, :polymorphic => true 
  
  
  def create_payment( backlog_clearance_source )
    self.is_paid = true 
    self.backlog_clearance_source_id = backlog_clearance_source.id 
    self.backlog_clearance_source_type = backlog_clearance_source.class.to_s
    self.save  
  end
  
  
end
