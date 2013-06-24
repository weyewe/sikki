class GroupLoanWeeklyPayment < ActiveRecord::Base
  # attr_accessible :title, :body
  has_one :transaction_activity, :as => :transaction_source 
  has_many :savings_entries, :as => :savings_source 
  
  belongs_to :group_loan_membership 
  belongs_to :group_loan 
  
  validate :number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
  validate :number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks
  validate :current_week_must_be_paid_if_there_is_enough_cash
  validate :amount_must_be_sufficient
  
  validate :only_savings_validity
  
  
  validate_presence_of :group_loan_membership_id 
  
  def number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
    if   self.group_loan_membership.present? and
         self.number_of_backlogs.present? and 
         self.group_loan_membership.unpaid_backlogs.count > self.number_of_backlogs
      self.errors.add(:number_of_backlogs, "Jumlah backlog yang belum dibayar: #{self.group_loan_membership.unpaid_backlogs.count}")
    end
  end
  
  def number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks
    if   self.group_loan_membership.present? and
         self.number_of_future_weeks.present?  and
         self.number_of_future_weeks > self.group_loan_membership.number_of_remaining_weeks - 1
       self.errors.add(:number_of_future_weeks, "Jumlah pembayaran kedepan yang belum dibayar: #{self.group_loan_membership.number_of_remaining_weeks - 1}")
    end
  end
  
  def only_savings_validity
    return if not group_loan_membership_id.present? or self.is_only_savings == false 
    
    if number_of_backlogs.present? and number_of_backlogs != 0 
      self.errors.add(:number_of_backlogs, "Hanya pembayaran tabungan")
    end
    
    if is_paying_current_week?
      self.errors.add(:is_paying_current_week, "Hanya pembayaran tabungan")
    end
    
    if voluntary_savings_withdrawal_amount.present? and voluntary_savings_withdrawal_amount != BigDecimal('0')
      self.errors.add(:voluntary_savings_withdrawal_amount, "Hanya pembayaran tabungan")
    end
    
    if cash_amount.present? and cash_amount !=  BigDecimal('0')
      self.errors.add(:cash_amount, "Tidak boleh 0")
    end
  end
  
  def amount_must_be_sufficient
    return if  not all_fields_present?
    
    if voluntary_savings_withdrawal_amount > group_loan_membership.total_voluntary_savings
      self.errors.add(:voluntary_savings_withdrawal_amount, "Jumlah tabungan sukarela: #{voluntary_savings_withdrawal_amount}")
    end
    
    
    if voluntary_savings_withdrawal_amount + cash_amount < base_payment_amount
      self.errors.add(:cash_amount, "Tidak cukup untuk pembayaran")
    end
  end
  
  def all_fields_present?
    group_loan_membership_id.present?              and      
    number_of_backlogs.present?                    and
    is_paying_current_week.present?                and
    is_only_savings.present?                       and
    is_no_payment.present?                         and
    number_of_future_weeks.present?                and
    voluntary_savings_withdrawal_amount.present?   and
    cash_amount.present?          
      
  end
  
  def base_payment_amount
    min_weekly_payment = self.group_loan_membership.group_loan_product.weekly_payment_amount
    total_weeks_paid*min_weekly_payment
  end
  
  def self.create_object(params)
    new_object                                     = self.new 
    new_object.group_loan_membership_id            = params[:group_loan_membership_id]
    new_object.number_of_backlogs                  = params[:number_of_backlogs]
    new_object.is_paying_current_week              = params[:is_paying_current_week]
    new_object.is_only_savings                     = params[:is_only_savings]
    new_object.is_no_payment                       = params[:is_no_payment]
    new_object.number_of_future_weeks              = params[:number_of_future_weeks]
    new_object.voluntary_savings_withdrawal_amount = BigDecimal(params[:voluntary_savings_withdrawal_amount])
    new_object.cash_amount                         = BigDecimal(params[:cash_amount])


    if new_object.save 
      new_object.create_transaction_activities
      new_object.create_savings_entries 
    end

    
    return new_object 
    
  end
  
  def update_object(params) 
  end
  
  def create_transaction_activities
   
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => self.cash_amount  ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings =>  self.voluntary_savings_withdrawal_amount,
                              :savings_direction => FUND_DIRECTION[:outgoing]
                              
  end
  
  def total_weeks_paid
    if is_paying_current_week?
      return = 1 + number_of_backlogs + number_of_future_weeks
    else
      return = 0 + number_of_backlogs + number_of_future_weeks
    end
  end
  
  def create_savings_entries
    
    number_of_weeks_paid = self.total_weeks_paid
    # compulsory_savings
    (1..number_of_weeks_paid).each do |x|
      SavingsEntry.create_group_loan_compulsory_savings_addition( self,  group_loan_membership.group_loan_product.min_savings)
      
       
    end
    
    # voluntary savings 
    extra_payment = self.cash_amount + self.voluntary_savings_withdrawal_amount  -  base_payment_amount
    if extra_payment > BigDecimal( '0' )
      SavingsEntry.create_group_loan_voluntary_savings_addition( self, extra_payment)
    end
    
  end
end
