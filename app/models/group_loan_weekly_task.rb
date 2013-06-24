class GroupLoanWeeklyTask < ActiveRecord::Base
  # attr_accessible :title, :body
  # week 1
  # week 2 
  # week 3 
  # week 4 
  # week 5 
  # week 6 
  # week 7
  # week 8 
  has_many :group_loan_weekly_responsibilities 
  has_many :group_loan_weekly_payments 
end