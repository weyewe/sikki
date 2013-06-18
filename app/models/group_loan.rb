class GroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :members, :through => :group_loan_memberships 
  has_many :group_loan_memberships 
  has_many :sub_group_loans 
  
  has_many :savings_entries, :as => :financial_product 
  
  
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
    self.group_loan_memberships.where(:is_active => true )
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
    not is_grace_period_payment_closed? 
  end
  
  def is_loan_disbursement_phase? 
    is_started? and 
    is_financial_education_finalized? and
    not is_loan_disbursed? and 
    not is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed?
  end
  
  def is_weekly_payment_period_phase?
    is_started? and 
    is_financial_education_finalized? and
    is_loan_disbursed? and 
    not is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed?
  end
  
  def is_grace_payment_period_phase?
    is_started? and 
    is_financial_education_finalized? and
    is_loan_disbursed? and 
    is_group_weekly_payment_closed? and 
    not is_grace_period_payment_closed?
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
      errors.add(:generic_errors, "Jumlah minggu cicilan harus lebih besar dari 0")
      return self 
    end
    
    if not self.all_group_loan_memberships_have_equal_duration?
      errors.add(:generic_errors, "Jumlah minggu cicilan harus lebih besar dari 0")
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
  
  def finalize_loan_disbursement
    
    if self.is_loan_disbursement_phase? and not self.is_loan_disbursement_finalized?
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
  end
  
  
  
  
  
  
end