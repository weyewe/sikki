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
    employee_id = self.employee_id 
    if not ( self.employee_id.present? and not Employee.find_by_id( employee_id ).nil? ) 
      self.errors.add(:employee_id, "Responsible employee must be selected")
    end
    
    if not  self.collection_datetime.present? 
      self.errors.add(:collection_datetime, "Harus ada waktu penarikan cicilan")
    end
    
    
  end
  
  def confirm(params)
    
    if self.unconfirmed_independent_payments.count != 0 
      self.errors.add(:generic_errors, 'Ada pembayaran independent yang belum di konfirmasi')
      return self 
    end
    
    if self.group_loan_weekly_responsibilities.where{
      attendance_status.eq  GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:unmarked]
    }.count != 0 
      self.errors.add(:generic_errors, "Ada kehadiran anggota yang belum ditandai")
      return self 
    end
    
    
    
    # if everyone has made payment for that week 
    glm_id_list_to_pay = self.group_loan_weekly_responsibilities.
                    where(:has_clearance => false).map{|x| x.group_loan_membership_id}
              
    expected_payment_count =  glm_id_list_to_pay.length      
    actual_weekly_payment_count = self.group_loan_weekly_payments.
                                where(:group_loan_membership_id =>glm_id_list_to_pay ).count            
    
    if expected_payment_count != actual_weekly_payment_count
      self.errors.add(:generic_errors, "Ada pembayaran mingguan yang belum dibayar")
      return self 
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
  
  
=begin
  Utility methods
=end

  def previous_weekly_task
    return self if self.week_number == 1 
    
    self.class.where(:week_number => self.week_number - 1 , :group_loan_id => self.group_loan_id ).first 
  end
  
  
end