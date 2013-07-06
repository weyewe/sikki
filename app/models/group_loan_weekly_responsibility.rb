
# group_loan_weekly_task can be closed if every group_loan_weekly_responsibility has clearance

class GroupLoanWeeklyResponsibility < ActiveRecord::Base
  attr_accessible :group_loan_membership_id, :group_loan_weekly_task_id
  belongs_to :group_loan_weekly_task
  belongs_to :group_loan_weekly_payment  
  
=begin
  # to clear the weekly responsibility: weekly payment
  # clearance source can be from GroupLoanIndependentPayment, or GroupLoanWeeklyPayment
  # 1. When it is payment for future weeks, it payment_status will be full_payment
  # 2. However, if it is payment for the current week, 
      the payment_status can be no payment declaration or 
=end
  def create_weekly_responsibility_clearance(clearance_source , payment_status )
    self.clearance_source_type = clearance_source.class.to_s
    self.clearance_source_id =  clearance_source.id 
    
    self.has_clearance = true 
    self.payment_status = payment_status
    self.save 
    
    if  payment_status == GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:only_savings]  or 
        payment_status == GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:no_payment_declared] 
      # generate backlog payment 
      GroupLoanBacklog.create :group_loan_membership_id => self.group_loan_membership_id, 
                                :group_loan_weekly_responsibility_id => self.id ,
                                :group_loan_id => self.group_loan_membership.group_loan_id 
    end
  end
  
  
  def assign_group_loan_weekly_payment(group_loan_weekly_payment)
    self.group_loan_weekly_payment_id = group_loan_weekly_payment.id 
    self.save 
  end
   
   # t.integer :attendance_status , :default => GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:unmarked]  #options: PRESENT, Absent, Late
   # t.text :attendance_note
   
   
   def self.attendance_statuses
     [
       GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:present],
       GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:absent],
       GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:late],
     ]
   end
   
   def mark_member_attendance(params)
     if self.group_loan_weekly_task.is_confirmed? 
       self.errors.add(:generic_errors, "Meeting mingguan sudah difinalisasi")
       return self 
     end
     
     if not params[:attendance_status].present?
       self.errors.add(:attendance_status, "Status kehadiran harus diisi: hadir, absen, atau telat")
       return self
     end
     
     if params[:attendance_status].present? and not self.class.attendance_statuses.include?(params[:attendance_status])
       self.errors.add(:attendance_status, "Status kehadiran harus diisi: hadir, absen, atau telat")
       return self
     end
     
     self.attendance_status = params[:attendance_status]
     self.attendance_note  = params[:attendance_note]
     self.save 
   end
   
  
  
=begin
  UTILITY methods to inspect the record's payment
=end

  def is_paid_on_the_same_weekly_payment?
    clearance_source_type == GroupLoanWeeklyPayment.to_s  and clearance_source_id == group_loan_weekly_payment_id
  end
  
  
  def is_extra_payment?
    ( clearance_source_type == GroupLoanWeeklyPayment.to_s  and clearance_source_id != group_loan_weekly_payment_id )  or 
    ( clearance_source_type == GroupLoanIndependentPayment.to_s and group_loan_weekly_payment_id != nil )
  end
  
  
end
