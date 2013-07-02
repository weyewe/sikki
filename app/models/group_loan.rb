class GroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :members, :through => :group_loan_memberships 
  has_many :group_loan_memberships 
  has_many :sub_group_loans 
  has_one :group_loan_default_payment 
  
  has_many :savings_entries, :as => :financial_product 
  has_many :group_loan_backlogs
  has_many :group_loan_grace_payments 
  
  
  has_many :group_loan_weekly_tasks # weekly payment, weekly attendance  
  validates_presence_of :office_id , :name,
                          :is_auto_deduct_admin_fee,
                          :is_auto_deduct_initial_savings, 
                          :is_compulsory_weekly_attendance
                          
  validates_uniqueness_of :name 
  
  
  def self.create_object(  params)
    new_object = self.new
    
    new_object.office_id = params[:office_id ]
    new_object.name                            = params[:name]
    new_object.is_auto_deduct_admin_fee        = true # params[:is_auto_deduct_admin_fee]
    new_object.is_auto_deduct_initial_savings  = true # params[:is_auto_deduct_initial_savings]
    new_object.is_compulsory_weekly_attendance = true 
    
    new_object.save
    
    return new_object 
  end
  
  def self.update_object( params ) 
    return nil if self.is_started?  
      
    self.name                            = params[:name]
    self.is_auto_deduct_admin_fee        = true #params[:is_auto_deduct_admin_fee]
    self.is_auto_deduct_initial_savings  = true #params[:is_auto_deduct_initial_savings]
    self.is_compulsory_weekly_attendance = true 
    
    self.save
    
    return self
  end
  
  
  def has_membership?( group_loan_membership)
    active_glm_id_list = self.active_group_loan_memberships.map {|x| x.id }
    
    active_glm_id_list.include?( group_loan_membership.id )
  end
  
  def set_group_leader( group_loan_membership ) 
    self.errors.add(:group_leader_id, "Harap pilih anggota dari group ini") if group_loan_membership.nil? 
    
     
    if self.has_membership?( group_loan_membership )  
      self.group_leader_id = group_loan_membership.id 
      self.save 
    else
      self.errors.add(:group_leader_id, "Bukan anggota dari pinjaman group ini")
    end
  end
  
  def active_group_loan_memberships
    if not self.is_closed?
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
    self.active_group_loan_memberships.each do |glm|
      return false if glm.group_loan_product.nil?
      duration_array << glm.group_loan_product.total_weeks 
    end
    
    return false if duration_array.uniq.length != 1
    return true 
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
    
    if self.group_loan_memberships.count == 0 
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
    self.active_group_loan_memberships.where{ is_attending_financial_education.eq nil}.count == 0 
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
  
  
  def create_default_payments 
    self.active_group_loan_memberships.each do |glm|
      GroupLoanDefaultPayment.create :group_loan_membership_id => glm.id
    end
  end
  
  def create_weekly_tasks
    (1..loan_duration).each do |week_number|
      GroupLoanWeeklyTask.create :week_number => week_number
    end
  end
  
  def create_weekly_responsibilities
    self.group_loan_weekly_tasks.each do |weekly_task|
      self.active_group_loan_memberships.order("id ASC").each do |glm|
        GroupLoanWeeklyResponsibility.create :group_loan_membership_id => glm.id ,
                                              :group_loan_weekly_task_id => weekly_task.id 
      end
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
    self.create_default_payments 
    self.create_weekly_tasks
    self.create_weekly_responsibilities 
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
    self.active_group_loan_memberships.where(:is_defaultee => true ) do |glm|
      glm.update_defaultee_savings_deduction
    end
  end
  
  def update_sub_group_non_defaultee_default_payment_contribution
    self.sub_group_loans.each do |sub_group|
      sub_group.update_sub_group_default_payment_contribution
    end
  end
  
  def update_group_non_defaultee_default_payment_contribution
    group_contribution = self.sub_group_loans.sum("sub_group_default_payment_contribution_amount")  * ( 50.0/100.0 )
    
    active_group_glm = self.active_group_loan_memberships.includes(:default_payment)
    number_of_non_defaultee_in_group = active_group_glm.where(:is_defaultee => false).count 
    
    if number_of_non_defaultee_in_group >  0
       group_non_defaultee_contribution = group_contribution / number_of_non_defaultee_in_group
       
       active_group_glm.where(:is_defaultee => false).each do |glm|
         default_payment = glm.default_payment 
         default_payment.amount_group_share = group_non_defaultee_contribution
         default_payment.save
       end
    end
  end
  
  #rounding up
  def update_total_amount_in_default_payment
    self.active_group_loan_memberships.includes(:default_payment).each do |glm|
      default_payment = glm.group_loan_default_payment 
      total_amount = BigDecimal("0")
      member = glm.member
      total_savings = member.saving_book.total
      total_compulsory_savings = glm.total_compulsory_savings
      total_voluntary_savings = glm.total_voluntary_savings 
       
      if  glm.is_defaultee?
        default_payment.calculate_defaultee_standard_resolution
      else
        default_payment.calculate_non_defaultee_standard_resolution 
      end 
    end
  end
  
  def calculate_default_resolution_amount 
    # for defaultee, compulsory and voluntary savings will be deducted 
    # for non-defaultee, only compulsory savings that will be deducted 
    self.update_deductible_savings  
    
    # sub_group share 
    self.update_sub_group_non_defaultee_default_payment_contribution   
    
    # group_share 
    self.update_group_non_defaultee_default_payment_contribution 
    
    self.reload
    self.update_total_amount_in_default_payment  # rounding up to the nearest exchange ( 500 rupiah )
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
    
    if self.group_loan_weekly_tasks.where(:is_confirmed =>true).count != self.loan_duration
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


  def update_total_default_amount
    amount  = BigDecimal('0')
    self.active_group_loan_memberships.joins(:group_loan_default_payment).each do |glm|
      amount += glm.group_loan_default_payment.standard_resolution_amount
    end
    self.total_default_amount = amount 
    self.save 
  end

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
     self.calculate_default_resolution_amount 
     self.reload 
     self.update_total_default_amount
  end
 
=begin
 Default Resolution
 Business Constraint: the members want the savings to be returned fast. 
 Solution: ??
=end
  def total_custom_default_resolution_amount
    amount  = BigDecimal('0')
    self.active_group_loan_memberships.joins(:group_loan_default_payment).each do |glm|
      amount += glm.group_loan_default_payment.custom_resolution_amount
    end
    
    amount 
  end
  
  
  def valid_custom_payment_amount?
    self.total_default_amount <= self.total_custom_default_resolution_amount 
  end

  def execute_default_resolution
    if self.default_payment_resolution_case == GROUP_LOAN_DEFAULT_PAYMENT_CASE[:standard]
      self.active_group_loan_memberships.each do |glm|
        glm.group_loan_default_payment.execute_standard_payment 
      end
    elsif self.default_payment_resolution_case == GROUP_LOAN_DEFAULT_PAYMENT_CASE[:custom]

      if not self.valid_custom_payment_amount?  
        errors.add(:generic_errors, "Jumlah default resolution dengan skema custom tidak cukup")
        return self
      end
      
      self.active_group_loan_memberships.each do |glm|
        glm.group_loan_default_payment.execute_custom_payment 
      end
    end
  end
  
  def port_compulsory_savings_to_voluntary_savings
    self.active_group_loan_memberships.each do |glm|
      glm.port_compulsory_savings_to_voluntary_savings 
    end
  end

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

  def port_voluntary_savings_to_savings_account
    # scenario: after default resolution, the member is allowed to withdraw all the voluntary savings
    # however, they are advised to save some of those voluntary savings
    # so, they returned some of the voluntary savings returned, to be saved as savings account.
    # in the administration, it is marked as porting voluntary savings and withdrawing the rest 
    self.active_group_loan_memberships.each do |glm|
      glm.port_voluntary_savings_to_savings_account 
    end
  end
  
  def deactivate_group_loan_memberships_on_group_loan_closing
    self.active_group_loan_memberships.each do |glm|
      glm.is_active = false 
      glm.deactivation_status = GROUP_LOAN_DEACTIVATION_STATUS[:finished_group_loan]
      glm.save
    end
  end
  
  
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
    self.port_voluntary_savings_to_savings_account # withdraw the remaining 
    self.deactivate_group_loan_memberships_on_group_loan_closing
  end
end