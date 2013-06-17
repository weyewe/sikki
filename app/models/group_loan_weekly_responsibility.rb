class GroupLoanWeeklyResponsibility < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :group_loan_weekly_task
end
