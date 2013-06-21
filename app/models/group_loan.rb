class GroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :members, :through => :group_loan_memberships 
  has_many :group_loan_memberships 
  has_many :sub_group_loans 
  
  has_many :savings_entries, :as => :financial_product 
  has_many :group_loan_backlogs
  
  
  has_many :group_loan_weekly_tasks # weekly payment, weekly attendance  
  validates_presence_of :office_id , :name,
                          :is_auto_deduct_admin_fee,
                          :is_auto_deduct_initial_savings, 
                          :is_compulsory_weekly_attendance
                          
  validates_uniqueness_of :name 
  
  
  def self.create_object( office, params)
    new_object = self.new
    new_object.office_id = office.id 
    
    new_object.name                            = params[:name]
    new_object.is_auto_deduct_admin_fee        = true # params[:is_auto_deduct_admin_fee]
    new_object.is_auto_deduct_initial_savings  = true # params[:is_auto_deduct_initial_savings]
    new_object.is_compulsory_weekly_attendance = params[:is_compulsory_weekly_attendance]
    
    new_object.save
    
    return new_object 
  end
  
  def self.update_object( params ) 
    return nil if self.is_started?  
      
    self.name                            = params[:name]
    self.is_auto_deduct_admin_fee        = true #params[:is_auto_deduct_admin_fee]
    self.is_auto_deduct_initial_savings  = true #params[:is_auto_deduct_initial_savings]
    self.is_compulsory_weekly_attendance = params[:is_compulsory_weekly_attendance]
    
    self.save
    
    return self
  end
  
  
  def active_group_loan_memberships
    if group_loan.is_closed?
      return self.group_loan_memberships.where(:is_active => true )
    else
      return self.group_loan_memberships.where{
        (is_active.eq false ) and 
        ( deactivation_status.eq GROUP_LOAN_DEACTIVATION_STATUS[:finished_group_loan] )
      }
    end 
  end
   
   
  def all_group_loan_memberships_have_equal_duration?
    duration_array = [] 
    self.group_loan_memberships.each do |glm|
      return false if glm.group_loan_product.nil?
      duration_array << glm.group_loan_product.total_weeks 
    end
    
    return false if duration_array.uniq.length != 1
  end
  
=begin
  Encode the group loan phases
=end

  def is_financial_education_phase?
    is_started? and 
    not is_financial_education_finalized? and
    not is_loan_disbursed? and 
    not is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed?  and 
    not is_default_payment_period_closed? and 
    not is_closed? 
  end
  
  def is_loan_disbursement_phase? 
    is_started? and 
    is_financial_education_finalized? and
    not is_loan_disbursed? and 
    not is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed? and 
    not is_default_payment_period_closed? and 
    not is_closed?
  end
  
  def is_weekly_payment_period_phase?
    is_started? and 
    is_financial_education_finalized? and
    is_loan_disbursed? and 
    not is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed? and 
    not is_default_payment_period_closed? and 
    not is_closed?
  end
  
  def is_grace_payment_period_phase?
    is_started? and 
    is_financial_education_finalized? and
    is_loan_disbursed? and 
    is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed? and 
    not is_default_payment_period_closed? and 
    not is_closed?
  end
  
  def is_default_payment_resolution_phase?
    is_started? and 
    is_financial_education_finalized? and
    is_loan_disbursed? and 
    is_group_weekly_payment_closed? and 
    is_grace_period_payment_closed? and 
    not is_default_payment_period_closed? and 
    not is_closed? 
  end
  
  def is_closing_phase?
    is_started? and 
    is_financial_education_finalized? and
    is_loan_disbursed? and 
    is_group_weekly_payment_closed? and 
    is_grace_period_payment_closed? and 
    is_default_payment_period_closed? and 
    not is_closed? 
  end
   
   
=begin
  Switching phases 
=end
  def start
    if  self.is_started?
      errors.add(:generic_errors, "Pinjaman grup sudah dimulai")
      return self 
    end
    
    if self.group_loan_memberhips.count == 0 
      errors.add(:generic_errors, "Jumlah anggota harus lebih besar dari 0")
      return self 
    end
    
    if not self.all_group_loan_memberships_have_equal_duration?
      errors.add(:generic_errors, "Durasi pinjaman harus sama")
      return self 
    end
    
    self.is_started = true
    self.save 
  end
  
=begin
Phase: financial education finalization
=end
  
  def is_all_financial_education_attendances_marked?
    self.active_group_loan_memberships.where( is_attending_financial_education.eq nil).count == 0 
  end
  
  def deactivate_memberships_for_absentee_in_financial_education
    self.active_group_loan_memberships.where(:is_attending_financial_education => false).each do |glm|
      glm.is_active = false 
      glm.deactivation_status = GROUP_LOAN_DEACTIVATION_STATUS[:financial_education_absent]
      glm.save
    end
  end
  
  def finalize_financial_education
    if self.is_financial_education_finalized?
      errors.add(:generic_errors, "Pendidikan keuangan sudah di finalisasi")
      return self
    end
    
    if not self.is_all_financial_education_attendances_marked?
      errors.add(:generic_errors, "Ada anggota yang kehadirannya di pendidikan keuangan belum ditandai")
      return self
    end
    
    self.is_financial_education_finalized = true 
    self.save 
    
    self.deactivate_memberships_for_absentee_in_financial_education  
  end
  
  
=begin
Phase: loan disbursement finalization
=end

  def is_all_loan_disbursement_attendances_marked?
    self.active_group_loan_memberships.where( is_attending_loan_disbursement.eq nil).count == 0 
  end
  
  def deactivate_memberships_for_absentee_in_loan_disbursement
    self.active_group_loan_memberships.where(:is_attending_loan_disbursement => false).each do |glm|
      glm.is_active = false 
      glm.deactivation_status = GROUP_LOAN_DEACTIVATION_STATUS[:loan_disbursement_absent]
      glm.save
    end
  end
  
  def execute_loan_disbursement_payment
    self.active_group_loan_memberships.each do |glm|
      GroupLoanDisbursement.create :group_loan_membership_id => glm.id 
    end
  end
  
  
  def create_default_payments_for_active_members
    self.active_group_loan_memberships.each do |x|
    end
  end
  
  def finalize_loan_disbursement
    
    if not self.is_loan_disbursement_phase?  
      errors.add(:generic_errors, "Bukan di fase penyerahan pinjaman")
      return self
    end
    
    if self.is_loan_disbursement_finalized?
      errors.add(:generic_errors, "Pinjaman keuangan sudah di finalisasi")
      return self
    end
    
    if not self.is_all_loan_disbursement_attendances_marked?
      errors.add(:generic_errors, "Ada anggota yang kehadirannya di penyerahan pinjaman belum ditandai")
      return self
    end
    
    self.is_loan_disbursement_finalized = true 
    self.save 
    
    self.deactivate_memberships_for_absentee_in_loan_disbursement
    
    self.execute_loan_disbursement_payment 
    self.create_default_payments_for_active_members
  end
  
=begin
 Weekly Payment 
=end

  def loan_duration
    duration_array = []
    self.active_group_loan_memberships.each do |glm|
      duration_array << glm.group_loan_subcription.total_weeks
    end
    
    return duration_array.uniq.first  
  end

 
  
  def setup_grace_period_payment 
    self.active_group_loan_memberships.joins(:default_payment).each do |glm|
      glm.set_grace_period_defaultee_status
      glm.calculate_outstanding_grace_period_amount
    end
  end
  
  def update_deductible_savings
    
  end
  
  def update_sub_group_non_defaultee_default_payment_contribution
    self.sub_group_loans.each do |sub_group|
      # sub_group.update_sub_group_default_payment_contribution(total_to_be_shared)
      sub_group.update_sub_group_default_payment_contribution
    end
  end
  
  def update_group_non_defaultee_default_payment_contribution
  end
  
  def update_total_amount_in_default_payment
  end
  
  def calculate_default_resolution_amount
    # line 1222  # check it out! 
    # for defaultee, update the total amount of cash deductible (compulsory saving + voluntary_savings)
    # for non defaultee, cash deductible is only from compulsory savings 
    self.update_deductible_savings  
    
    # self.distribute_default_resolution
    total_to_be_shared = self.default_payment_amount_to_be_shared
    self.reload
    self.update_sub_group_non_defaultee_default_payment_contribution 
    self.reload
    self.update_group_non_defaultee_default_payment_contribution 
    self.reload
    
    # rounding up the default payment (total must be paid by each member)
    self.update_total_amount_in_default_payment
    
    # extract the amount from subgroup
    # extract the amount from group
    # round up
  end
  
  def finalize_weekly_payment_period
    if not self.is_weekly_payment_period_phase?  
      errors.add(:generic_errors, "Bukan di fase pembayaran mingguan")
      return self
    end
    
    if self.is_weekly_payment_period_closed?
      errors.add(:generic_errors, "Fase Pembayaran mingguan sudah ditutup")
      return self
    end
    
    if self.group_loan_weekly_tasks.where(:is_closed =>true).count != self.loan_duration
      errors.add(:generic_errors, "Ada Pembayaran mingguan yang belum di tutup")
      return self
    end
    
    
    self.is_weekly_payment_period_closed = true
    self.save 
    
    self.setup_grace_period_payment 
    
    self.calculate_default_resolution_amount #member wants to know the money they owe 
    # on all grace period payment, calculate_default_resolution_amount  (it changes!)
  end

=begin
 Grace Period
=end

  # def calculate_default_payment_amount
  #   # run through all active_glm, update the default_payment status and amount
  #   # 
  #   # data from old KKI
  #   self.update_default_payment_status  # if the amount outstanding is 0, it is non_defaultee 
  #   # self.update_default_payment_in_grace_period
  # end


  def finalize_grace_payment_period
     if not self.is_grace_payment_period_phase?  
       errors.add(:generic_errors, "Bukan di fase penyerahan grace period payment")
       return self
     end

     if self.is_grace_payment_period_closed?
       errors.add(:generic_errors, "Pembayaran grace period sudah tutup")
       return self
     end
     
     self.is_grace_payment_period_closed = true
     self.save 
     # last update 
     self.calculate_default_resolution_amount 
  end
 
=begin
 Default Resolution
 Business Constraint: the members want the savings to be returned fast. 
=end

  def finalize_default_resolution_period
    if not self.is_default_payment_resolution_phase?  
      errors.add(:generic_errors, "Bukan di fase pemotongan tabungan wajib untuk menutupi default")
      return self
    end

    if self.is_default_payment_period_closed?
      errors.add(:generic_errors, "Fase pemotongan tabungan wajib sudah tutup")
      return self
    end

    self.is_grace_payment_period_closed = true
    self.save 
    self.execute_default_resolution # specified in the group loan: default or custom 
    self.port_compulsory_savings_to_voluntary_savings  
  end

=begin
 Returning the voluntary savings  period
=end

# field worker returns to the office, brings the money re-saved @savings account
# for every withdrawal, create group loan savings withdrawal
# then, click close group loan. DONE. 
  def close
    if not self.is_closing_phase?  
      errors.add(:generic_errors, "Bukan di fase  penutupan pinjaman group")
      return self
    end

    if self.is_closed?
      errors.add(:generic_errors, "Fase penutupan pinjaman sudah tutup")
      return self
    end

    self.is_closed = true
    self.save 
    self.remaining_voluntary_savings_to_savings_account
  end
  
  
  
  # group_loan_voluntary_savings_withdrawal.rb
  # group_loan_voluntary_savings_withdrawal.rb
  # group_loan_port_voluntary_savings.rb
  
  
  
  
  
end