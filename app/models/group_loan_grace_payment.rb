class GroupLoanGracePayment < ActiveRecord::Base
  # attr_accessible :title, :body
  has_one :transaction_activity, :as => :transaction_source 
  belongs_to :group_loan_membership 
  belongs_to :group_loan
  
  validates_presence_of :group_loan_membership_id, :group_loan_id, :employee_id,
                        :voluntary_savings_withdrawal_amount, :cash_amount

  # only working for the CREATE case ,
  # for UPDATE case, we need a branch.. self.is_persisted? 
  # example update case: in confirm.. it is an update. but, the validation will be called 
  validate :group_loan_in_grace_period_phase 
  validate :no_negative_payment_amount
  validate :amount_must_be_sufficient
  validate :no_total_zero_payment 
  
  
=begin
  VALIDATION
=end
  def group_loan_in_grace_period_phase
    return if  not all_fields_present?
    
    if not group_loan.is_grace_payment_period_phase?
      self.errors.add(:generic_errors, "Tidak dalam fase grace period ")
    end
  end
  
  def no_negative_payment_amount
    return if  not all_fields_present?
    
    self.errors.add(:cash_amount, "Tidak cukup untuk pembayaran") if cash_amount < BigDecimal('0')
    self.errors.add(:voluntary_savings_withdrawal_amount, "Tidak cukup untuk pembayaran") if voluntary_savings_withdrawal_amount < BigDecimal('0')
  end
  
  def amount_must_be_sufficient
    return if  not all_fields_present?
    
    if voluntary_savings_withdrawal_amount > group_loan_membership.total_voluntary_savings
      self.errors.add(:voluntary_savings_withdrawal_amount, "Jumlah tabungan sukarela: #{group_loan_membership.total_voluntary_savings}")
    end
  end
  
  def no_total_zero_payment
    return if not all_fields_present? 
    
    if cash_amount == BigDecimal('0') and voluntary_savings_withdrawal_amount == BigDecimal('0')
      self.errors.add(:cash_amount, "Kas dan penggunaan tabungan sukarela tidak boleh 0 ")  
      self.errors.add(:voluntary_savings_withdrawal_amount, "Kas dan penggunaan tabungan sukarela tidak boleh 0 ")  
    end
  end
  
  def all_fields_present?
    group_loan_membership_id.present?              and   
    group_loan_id.present?                         and   
    employee_id.present?                           and   
    voluntary_savings_withdrawal_amount.present?   and
    cash_amount.present? 
  end
  
 
  
  
=begin
  base CRUD 
=end


  def total_payment 
     self.cash_amount + self.voluntary_savings_withdrawal_amount 
  end
  
  def update_amount_paid
    outstanding_grace_period = group_loan_membership.outstanding_grace_period_amount
    
    if total_payment > outstanding_grace_period
      self.amount_paid = outstanding_grace_period
    else
      self.amount_paid = total_payment
    end
    
    self.save 
  end
  
  def self.create_object( params ) 
    new_object                          = self.new 
    new_object.group_loan_membership_id = params[:group_loan_membership_id]
    new_object.group_loan_id            = params[:group_loan_id]
    new_object.employee_id              = params[:employee_id]
    new_object.collection_datetime      = params[:collection_datetime]
     
    new_object.voluntary_savings_withdrawal_amount = BigDecimal(params[:voluntary_savings_withdrawal_amount])
    new_object.cash_amount                         = BigDecimal(params[:cash_amount])
    
    if new_object.save
      self.update_amount_paid
    end
    
    return new_object 
  end
  
  def update_object
    return nil if self.is_confirmed? 
  end
  
  
  
  def create_transaction_activities
    member = group_loan_membership.member 
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => self.cash_amount  ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings =>  self.voluntary_savings_withdrawal_amount,
                              :savings_direction => FUND_DIRECTION[:outgoing],
                              :member_id => member.id, 
                              :office_id => member.office_id
  end
  
  def create_savings_entries
    if voluntary_savings_withdrawal_amount > BigDecimal('0')
      SavingsEntry.create_group_loan_voluntary_savings_withdrawal( self,  self.voluntary_savings_withdrawal_amount )
    end

    extra_payment = self.total_payment  - self.amount_paid 
    
    if extra_payment > BigDecimal( '0' )
      SavingsEntry.create_group_loan_voluntary_savings_addition( self, extra_payment)
    end
  end
  
  # in transaction 
  def confirm(params)
    return nil if self.is_confirmed? 
     
    self.is_confirmed = true 
    self.confirmation_datetime = DateTime.now 
    self.save
    
    self.create_transaction_activities
    self.create_savings_entries # using the old outstanding grace period amount 
    
    glm = self.group_loan_membership
    glm.calculate_outstanding_grace_period_amount
    glm.reload
    glm.update_defaultee_status 
    
  end
  
  def delete_object
    return nil if self.is_confirmed? 
    self.destroy 
  end
end
