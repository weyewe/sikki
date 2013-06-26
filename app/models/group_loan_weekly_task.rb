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
  
  has_many :group_loan_independent_payments 
  
  
  def unconfirmed_independent_payments
    self.group_loan_independent_payments.where(:is_confirmed => false )
  end
  
  def confirm
    if self.unconfirmed_independent_payments.count != 0 
      msg = "Ada pembayaran independent yang belum di konfirmasi"
      self.errors.add(:generic_errors, msg)
    end
  end
  
  
end