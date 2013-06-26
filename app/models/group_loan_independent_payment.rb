=begin
  Can only be used to pay for 
  1.  voluntary savings with cash     + savings withdrawal
  2.  future weeks payment
  3.  backlog payment 
=end

class GroupLoanIndependentPayment < ActiveRecord::Base
  # attr_accessible :title, :body
  has_one :transaction_activity, :as => :transaction_source 
  belongs_to :group_loan 
  belongs_to :group_loan_membership 
  
  validate :must_be_attached_to_unconfirmed_weekly_task
  validate :number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
  validate :number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks 
  validate :amount_must_be_sufficient
  validate :no_negative_payment_amount
  
  
  
  def all_fields_present?
    group_loan_membership_id.present?              and   
    group_loan_weekly_task_id.present?             and       
    number_of_backlogs.present?                    and
    number_of_future_weeks.present?                and
    voluntary_savings_withdrawal_amount.present?   and
    cash_amount.present? 
  end
  
  
  
  def must_be_attached_to_unconfirmed_weekly_task 
    if self.group_loan.group_loan_weekly_tasks.where(:is_confirmed => false).count == 0
      self.errors.add(:generic_errors, "Fase pembayaran cicilan sudah selesai.")
    end
  end
  
  
  
  def number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
    return if not all_fields_present?
    
    if   self.group_loan_membership.unpaid_backlogs.count > self.number_of_backlogs
      self.errors.add(:number_of_backlogs, "Jumlah backlog yang belum dibayar: #{self.group_loan_membership.unpaid_backlogs.count}")
    end
  end
  
  
  def number_of_available_future_weeks 
    return self.group_loan_membership.number_of_remaining_weeks  
  end
  
  def number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks 
    return if not all_fields_present?
    
    if   self.number_of_future_weeks > self.number_of_available_future_weeks 
       self.errors.add(:number_of_future_weeks, "Jumlah pembayaran kedepan yang belum dibayar: #{self.number_of_available_future_weeks}")
    end
  end
  
  def amount_must_be_sufficient
    return if  not all_fields_present?
    
    if voluntary_savings_withdrawal_amount > group_loan_membership.total_voluntary_savings
      self.errors.add(:voluntary_savings_withdrawal_amount, "Jumlah tabungan sukarela: #{group_loan_membership.total_voluntary_savings}")
    end
    
    
    if voluntary_savings_withdrawal_amount + cash_amount < base_payment_amount
      self.errors.add(:cash_amount, "Tidak cukup untuk pembayaran")
    end
  end
  
  def no_negative_payment_amount
    self.errors.add(:cash_amount, "Tidak cukup untuk pembayaran") if cash_amount < BigDecimal('0')
    self.errors.add(:voluntary_savings_withdrawal_amount, "Tidak cukup untuk pembayaran") if voluntary_savings_withdrawal_amount < BigDecimal('0')
  end
  
  def first_unconfirmed_weekly_task
    group_loan.group_loan_weekly_tasks.where(:is_confirmed => false).order("id ASC").first 
  end
  
  def self.create_object( params ) 
    new_object                                     = self.new 
    new_object.group_loan_weekly_task_id           = params[:group_loan_weekly_task_id]
    new_object.group_loan_membership_id            = params[:group_loan_membership_id]
    new_object.group_loan_id                       = params[:group_loan_id]
    new_object.employee_id                         = params[:employee_id]
    
    new_object.number_of_backlogs                  = params[:number_of_backlogs]
    new_object.number_of_future_weeks              = params[:number_of_future_weeks]
    new_object.voluntary_savings_withdrawal_amount = BigDecimal(params[:voluntary_savings_withdrawal_amount])
    new_object.cash_amount                         = BigDecimal(params[:cash_amount])
    
    new_object.save
    
    return new_object 
  end
  
  def update_object( params ) 
  end
  
  
  def create_group_backlog_payments
    self.group_loan_membership.unpaid_backlogs.limit(self.number_of_backlogs).each do |backlog|
      backlog.create_payment( self ) 
    end
  end
  
  
  def create_future_week_payments
    count = 1 
    group_loan_membership.remaining_weeks.each do |weekly_responsibility|
      # independent payment => don't exclude the current weekly responsibility 
      weekly_responsibility.create_weekly_responsibility_clearance( self , GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:full_payment] )
      break if count == number_of_future_weeks
      count += 1 
    end
  end
  
  
  def update_affected_weekly_responsibilities
    self.create_group_backlog_payments  if self.number_of_backlogs != 0 
    self.create_future_week_payments  if self.number_of_future_weeks != 0 
  end
  
  
  def total_weeks_paid
    number_of_backlogs + number_of_future_weeks
  end
  
  def base_payment_amount
    min_weekly_payment = self.group_loan_membership.group_loan_product.weekly_payment_amount
    total_weeks_paid*min_weekly_payment
  end
  
  
  
  def create_transaction_activities
   
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => self.cash_amount  ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings =>  self.voluntary_savings_withdrawal_amount,
                              :savings_direction => FUND_DIRECTION[:outgoing]
                              
  end
  
  
  def create_savings_entries
    number_of_weeks_paid = self.total_weeks_paid
    
      
     #compulsory savings, from mandatory weekly payment 
     (1..number_of_weeks_paid).each do |x|
       SavingsEntry.create_group_loan_compulsory_savings_addition( self,  group_loan_membership.group_loan_product.min_savings)
     end

     #voluntary savings 
     extra_payment = self.cash_amount + self.voluntary_savings_withdrawal_amount  -  base_payment_amount
     if extra_payment > BigDecimal( '0' )
       SavingsEntry.create_group_loan_voluntary_savings_addition( self, extra_payment)
     end
     
  end
  
  
  
  def confirm
    return if self.is_confirmed? 
    
    new_object.update_affected_weekly_responsibilities 
    new_object.create_transaction_activities
    new_object.create_savings_entries
  end
  
  
end
