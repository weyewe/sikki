class GroupLoanWeeklyTask < ActiveRecord::Base
  attr_accessible :week_number , :group_loan_id
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
  belongs_to :group_loan 
  
  
  def unconfirmed_independent_payments
    self.group_loan_independent_payments.where(:is_confirmed => false )
  end
  
  def validate_confirmation_data
    if not ( self.employee_id.present? and  Employee.find_by_id(self.employee_id).count != 0 ) 
      self.errors.add(:employee_id, "Responsible employee must be selected")
    end
    
    if  self.collection_datetime.present? 
      self.errors.add(:collection_datetime, "Harus ada waktu penarikan cicilan")
    end
    
    
  end
  
  def confirm(params)
    if self.unconfirmed_independent_payments.count != 0 
      msg = "Ada pembayaran independent yang belum di konfirmasi"
      self.errors.add(:generic_errors, msg)
    end
    
    self.is_confirmed = true 
    self.confirmation_datetime = DateTime.now 
    
    self.collection_datetime = params[:collection_datetime]
    self.employee_id = params[:employee_id]
    
    self.validate_confirmation_data
    return self if self.errors.size != 0 
    
    self.save
    self.group_loan_weekly_payments.each do |weekly_payment|
      weekly_payment.confirm 
    end
   
  end
  
  
end