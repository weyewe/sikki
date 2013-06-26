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
  
  has_many :group_loan_backlogs 
  
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
  
  def mark_financial_education_attendance( params )
    if self.group_loan.is_financial_education_finalized? 
      errors.add(:is_attending_financial_education, "Tidak bisa edit. Pendidikan keuangan sudah difinalisasi")
      return 
    end
    
    self.is_attending_financial_education = params[:is_attending_financial_education]
    self.save 
  end
  
   
  def total_unpaid_backlogs
    unpaid_backlogs.count 
  end
  
  def calculate_outstanding_grace_period_amount
    initial_outstanding_grace_period_amount = self.total_unpaid_backlogs * self.group_loan_product.grace_period_weekly_payment_amount
    
    paid_amount = self.group_loan_grace_period_payments.where(:is_confirmed => true).sum("amount_paid_to_cover_outstanding_grace_payment")   
    
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

  def set_grace_period_defaultee_status
    if self.group_loan_backlogs.where(:is_paid => false).count != 0 
      self.is_defaultee = true 
      self.save 
    end
  end
  
  def port_compulsory_savings_to_voluntary_savings
    GroupLoanPortCompulsorySavings.create :group_loan_membership_id => self.id 
    
    self.update_total_compulsory_savings
    self.update_total_voluntary_savings
  end
  
  def port_voluntary_savings_to_savings_account
    GroupLoanVoluntarySavingsWithdrawal.create  :group_loan_membership_id => self.id , 
                                                :amount => self.closing_withdrawal_amount
                                                
    GroupLoanPortVoluntarySavings.create :group_loan_membership_id => self.id , 
                                          :amount => self.closing_savings_amount
    
    self.update_total_voluntary_savings # re-sum all transactions 
    self.member.update_total_savings_account # fuck.. use the buffered state 
  end
end
