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
  
  validate :must_be_attached_to_unconfirmed_weekly_task
  validate :number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
  validate :number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks 
  validate :amount_must_be_sufficient
  validate :no_negative_payment_amount
  
  
  
  def must_be_attached_to_unconfirmed_weekly_task 
    if self.group_loan.group_loan_weekly_tasks.where(:is_confirmed => false).count == 0
      self.errors.add(:generic_errors, "Fase pembayaran cicilan sudah selesai.")
    end
  end
  
  def number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
  end
  
  def number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks
  end
  
  def amount_must_be_sufficient
  end
  
  def no_negative_payment_amount
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
    
      
     #compulsory savings
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
