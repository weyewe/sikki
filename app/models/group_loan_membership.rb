class GroupLoanMembership < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office
  belongs_to :member 
  belongs_to :group_loan 
  belongs_to :sub_group_loan 
  
  has_one :group_loan_subcription
  has_one :group_loan_product, :through => :group_loan_subcription 
  
  has_one :group_loan_default_payment  #checked  
  has_one :group_loan_disbursement  #checked 
  has_many :group_loan_weekly_payments   # we need the model. A weekly task 
  # => can be paid through backlog payment, weekly payment, or independent payment 
  has_many :group_loan_independent_payments
  has_many :group_loan_grace_payments
  has_many :group_loan_weekly_responsibilities
  has_many :group_loan_voluntary_savings_withdrawals 
  
  has_many :group_loan_backlogs 
  
  validates_presence_of :group_loan_id, :member_id 
  validate :no_active_membership_of_another_group_loan
  
  def no_active_membership_of_another_group_loan
    return if self.persisted? or not self.member_id.present? 
    
    if GroupLoanMembership.where(:is_active => true, :member_id => self.member_id ).count != 0
      self.errors.add(:member_id , "Sudah ada pinjaman di group lainnya")
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.group_loan_id      = params[:group_loan_id] 
    new_object.sub_group_loan_id  = params[:sub_group_loan_id]
    new_object.member_id          = params[:member_id]
    new_object.save
    
    return new_object 
  end
  
  def update_object( params ) 
    return nil if self.group_loan.is_started? 
    
    self.sub_group_loan_id  = params[:sub_group_loan_id] 
    self.member_id = params[:member_id]
    self.save
  end
  
  def delete_object
    return nil if self.group_loan.is_started? 
    
    if not self.group_loan_subcription.nil?
      self.group_loan_subcription.destroy
    end
    
    self.destroy 
  end
  
  def group_loan_product
    self.group_loan_subcription.group_loan_product 
  end
  
  def mark_financial_education_attendance( params )
    if not self.group_loan.is_financial_education_phase?  
      errors.add(:is_attending_financial_education, "Tidak bisa edit. Bukan di fase pendidikan keuangan")
      return 
    end
    
    self.is_attending_financial_education = params[:is_attending_financial_education]
    self.save 
  end
  
  def mark_loan_disbursement_attendance( params )
    if not self.group_loan.is_loan_disbursement_phase?
      errors.add(:is_attending_loan_disbursement, "Tidak bisa edit. Penyaluran Pinjaman sudah difinalisasi")
      return 
    end
    
    if not self.is_active?
      errors.add(:is_attending_loan_disbursement, "Tidak bisa edit. Anggota ini sudah tidak aktif")
      return 
    end
    
    self.is_attending_loan_disbursement = params[:is_attending_loan_disbursement]
    self.save 
  end
  
   
  def total_unpaid_backlogs
    unpaid_backlogs.count 
  end
  
  def calculate_outstanding_grace_period_amount
    initial_outstanding_grace_period_amount = self.total_unpaid_backlogs * self.group_loan_product.grace_period_weekly_payment_amount
    
    paid_amount = self.group_loan_grace_period_payments.where(:is_confirmed => true).sum("amount_paid")   
    
    self.outstanding_grace_period_amount = initial_outstanding_grace_period_amount - paid_amount
    self.save
  end
  
  def remaining_weeks
    self.group_loan_weekly_responsibilities.where(:has_clearance => false ).order("group_loan_weekly_task_id ASC")
  end
  
  def number_of_remaining_weeks # excluding the current week 
    self.remaining_weeks.count 
  end
  
  def unpaid_backlogs
    self.group_loan_backlogs.where(:is_paid => false ) 
  end
  
  def has_cleared_weekly_payment?(group_loan_weekly_task)
    self.remaining_weeks.where(:group_loan_weekly_task_id => group_loan_weekly_task.id ).count == 0 
  end
  
  def weekly_responsibility(group_loan_weekly_task)
    self.group_loan_weekly_responsibilities.where(:group_loan_weekly_task_id => group_loan_weekly_task.id ).first 
  end
  
=begin
  Entering the grace period
=end

  def update_defaultee_savings_deduction
    default_payment = self.default_payment 
    total_compulsory_savings = self.total_compulsory_savings
    total_voluntary_savings = self.total_voluntary_savings
    total_deductible_member_savings = total_compulsory_savings + total_extra_savings
    
    # refresh the state 
    default_payment.compulsory_savings_deduction_amount = BigDecimal("0")
    default_payment.voluntary_savings_deduction_amount = BigDecimal("0")
    default_payment.amount_to_be_shared_with_non_defaultee = BigDecimal("0")
    
    total_amount = default_payment.outstanding_grace_period_amount 
    
    if total_amount <= total_compulsory_savings
      default_payment.compulsory_savings_deduction_amount = total_amount 
    elsif total_amount > total_compulsory_savings &&  total_amount <= total_deductible_member_savings 
      default_payment.amount_of_compulsory_savings_deduction = total_compulsory_savings 
      default_payment.voluntary_savings_deduction_amount = total_amount  - total_compulsory_savings
    elsif total_amount > total_deductible_member_savings 
      default_payment.compulsory_savings_deduction_amount = total_compulsory_savings 
      default_payment.voluntary_savings_deduction_amount = total_extra_savings
      default_payment.amount_to_be_shared_with_non_defaultee = total_amount - total_deductible_member_savings
    end 
    
    default_payment.save
  end

# only called during grace period setup phase 
  def set_grace_period_defaultee_status
    if self.group_loan_backlogs.where(:is_paid => false).count != 0 
      self.is_defaultee = true 
      self.save 
    end
  end
  
  def update_defaultee_status
    if self.outstanding_grace_period_amount == BigDecimal('0')
      self.is_defaultee = false 
      self.save 
    end
  end
  
  def port_compulsory_savings_to_voluntary_savings
    GroupLoanPortCompulsorySavings.create :group_loan_membership_id => self.id 
    
    self.update_total_compulsory_savings
    self.update_total_voluntary_savings
  end
  
  
  def assign_closing_withdrawal_amount(params)
    # return if the group loan is closed
    if group_loan.is_closed? 
      self.errors.add(:generic_errors, "Pinjaman kumpulan sudah ditutup. Tidak boleh edit.")
      return self
    end
    
    if amount > total_voluntary_savings
      self.errors.add(:closing_withdrawal_amount, "Penarikan tidak boleh lebih dari #{total_voluntary_savings}")
      return self
    end
    
    if not params[:savings_return_employee_id].present? 
      self.errors.add(:savings_return_employee_id, "Harus menulis nama karyawan yang mengembalikan tabungan")
      return self
    end
    
    self.closing_withdrawal_amount  = BigDecimal( params[:closing_withdrawal_amount])
    self.closing_savings_amount = total_voluntary_savings - BigDecimal( params[:closing_withdrawal_amount])
    self.savings_return_employee_id = params[:savings_return_employee_id]
    self.save 
  end
  
  def port_voluntary_savings_to_savings_account
    # scenario: before closing group loan, key in the savings not withdrawn...
    
    
    if self.closing_withdrawal_amount != BigDecimal('0')
      withdrawal = GroupLoanVoluntarySavingsWithdrawal.create  :group_loan_membership_id => self.id , 
                                                :amount => self.closing_withdrawal_amount,
                                                :employee_id => self.savings_return_employee_id, 
                                                :group_loan_id => self.group_loan_id 
                                                
                                                
      withdrawal.confirm 
    end                                            
                                                
    if self.closing_savings_amount != BigDecimal('0')
      GroupLoanPortVoluntarySavings.create :group_loan_membership_id => self.id , 
                                          :amount =>  self.closing_savings_amount
    end
    
    self.update_total_voluntary_savings # re-sum all transactions   # do we need to do it?
    # it can always be re constructed.. just exclude the GroupLoanPortVoluntarySavings 
    # anyway, this is expired => as a data.. to show the history of group loan membership
    self.member.update_total_savings_account # fuck.. use the buffered state 
  end
  
  
  def update_total_compulsory_savings
    incoming = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
      :financial_product_type => GroupLoan.to_s, 
      :financial_product_id => self.group_loan_id ,
      :direction => FUND_DIRECTION[:incoming]
    ).sum("amount")   
    
    outgoing = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
      :financial_product_type => GroupLoan.to_s, 
      :financial_product_id => self.group_loan_id ,
      :direction => FUND_DIRECTION[:outgoing]
    ).sum("amount")
    
    self.total_compulsory_savings = incoming - outgoing 
    self.save 
    
  end
  
  def update_total_voluntary_savings 
    incoming = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:group_loan_voluntary_savings],
      :financial_product_type => GroupLoan.to_s, 
      :financial_product_id => self.group_loan_id ,
      :direction => FUND_DIRECTION[:incoming]
    ).sum("amount")   
    
    outgoing = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:group_loan_voluntary_savings],
      :financial_product_type => GroupLoan.to_s, 
      :financial_product_id => self.group_loan_id ,
      :direction => FUND_DIRECTION[:outgoing]
    ).sum("amount")
    
    self.total_voluntary_savings = incoming - outgoing 
    self.save
  end
end
