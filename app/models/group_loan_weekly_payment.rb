class GroupLoanWeeklyPayment < ActiveRecord::Base
  # attr_accessible :title, :body
  has_one :transaction_activity, :as => :transaction_source 
  has_many :savings_entries, :as => :savings_source 
  
  has_many :group_loan_backlogs, :as => :backlog_clearance_source 
  
  belongs_to :group_loan_membership 
  belongs_to :group_loan 
  
  
  # we have to separate validation for update and object creation 
  # these shite are working for CREATE
  validate :can_only_select_one_weekly_payment_mode
  validate :number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
  validate :number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks_excluding_current_week
  validate :amount_must_be_sufficient
  validate :no_negative_payment_amount
  validate :current_week_payment_is_the_highest_priority
  validate :no_double_group_loan_weekly_payment  # for a given group_loan_weekly_task 
  validate :only_savings_validity
  validate :total_payment_must_be_zero_if_no_payment_declaration
  validate :total_payment_must_not_be_zero_if_non_no_payment_declaration

  
  # How about validation mechanism for UPDATE? => banzai! 
  
  
  
  
  validates_presence_of :group_loan_membership_id , :group_loan_weekly_task_id 
  
  def can_only_select_one_weekly_payment_mode
    if all_fields_present?  
      
      # case 1: current week has not been paid. 
      if not group_loan_membership.has_cleared_current_week?(group_loan_weekly_task)
        results = [ 
          is_paying_current_week, 
          is_only_savings, 
          is_no_payment 
        ]

        truth_counter = 0 

        resuts.each do |truth_value|
          if truth_value == true 
            truth_counter += 1 
          end
        end

        if truth_counter != 1 
          msg = 'Hanya boleh memilih salah satu: pembayaran minggu ini, " +
                " hanya tabungan, tidak ada pembayaran, atau hanya pembayaran extra'
                
          self.errors.add(:is_paying_current_week , msg)  if is_paying_current_week?
          self.errors.add(:is_only_savings , msg)  if is_only_savings?
          self.errors.add(:is_no_payment , msg)  if is_no_payment?
        end
        
        if is_only_voluntary_savings?
          self.errors.add(:is_only_voluntary_savings , 'Hanya dapat dipilih jika minggu ini sudah dibayar sebelumnya')
        end
      end
      
      # case 2: current week has been paid (past). options: 
      # => 1. only_voluntary_savings    if there is no backlog or future payments
      # => 2. only_voluntary_savings should be false if there is backlog or future payment
      if  group_loan_membership.has_cleared_current_week?(group_loan_weekly_task)
        self.errors.add(:is_paying_current_week, "Sudah dibayar") if is_paying_current_week 
        self.errors.add(:is_only_savings, "Sudah dibayar") if is_only_savings 
        self.errors.add(:is_no_payment, "Sudah dibayar") if is_no_payment 
        
        if  ( number_of_future_weeks != 0 or number_of_backlogs != 0 )  and 
            is_only_voluntary_savings
          self.errors.add(:is_only_voluntary_savings , 'Ada pembayaran backlog atau untuk minggu depan')
        end
        
        if  ( number_of_future_weeks == 0 and number_of_backlogs == 0 )  and 
            not is_only_voluntary_savings
          self.errors.add(:is_only_voluntary_savings , 'Pembayaran harus untuk tabungan sukarela')
        end
      end
     
    end
  end
  
  def number_of_backlogs_payment_must_not_exceed_unpaid_backlogs
    return if not all_fields_present?
    
    if   self.group_loan_membership.unpaid_backlogs.count > self.number_of_backlogs
      self.errors.add(:number_of_backlogs, "Jumlah backlog yang belum dibayar: #{self.group_loan_membership.unpaid_backlogs.count}")
    end
  end
  
  
  def number_of_available_future_weeks 
    if group_loan_membership.has_cleared_weekly_payment?(group_loan_weekly_task)
      return self.group_loan_membership.number_of_remaining_weeks 
    else
      return self.group_loan_membership.number_of_remaining_weeks  - 1 
    end
  end
  
  def number_of_future_weeks_payment_must_not_exceed_the_remaining_weeks_excluding_current_week
    return if not all_fields_present?
    
    if   self.number_of_future_weeks > self.number_of_available_future_weeks 
       self.errors.add(:number_of_future_weeks, "Jumlah pembayaran kedepan yang belum dibayar: #{self.number_of_available_future_weeks}")
    end
  end
  
  
  def only_savings_validity
    return if not all_fields_present? 
    return if not is_only_savings?
    
    if number_of_backlogs.present? and number_of_backlogs != 0 
      self.errors.add(:number_of_backlogs, "Hanya pembayaran tabungan")
    end
    
    if is_paying_current_week?
      self.errors.add(:is_paying_current_week, "Hanya pembayaran tabungan")
    end
    
    if voluntary_savings_withdrawal_amount.present? and voluntary_savings_withdrawal_amount != BigDecimal('0')
      self.errors.add(:voluntary_savings_withdrawal_amount, "Hanya pembayaran tabungan")
    end
    
    if cash_amount.present? and cash_amount ==  BigDecimal('0')
      self.errors.add(:cash_amount, "Tidak boleh 0")
    end
  end
  
  
  
  def total_payment_must_be_zero_if_no_payment_declaration
    return if  not all_fields_present?
    if is_no_payment?
      self.errors.add(:voluntary_savings_withdrawal_amount, "Tidak ada pembayaran") if voluntary_savings_withdrawal_amount != BigDecimal('0')
      self.errors.add(:cash_amount, "Tidak ada pembayaran") if cash_amount != BigDecimal('0')  
    end
  end
  
  def total_payment_must_not_be_zero_if_non_no_payment_declaration
    return if  not all_fields_present?
    
    if  not is_no_payment? and 
        voluntary_savings_withdrawal_amount + cash_amount <= BigDecimal('0')
      
      msg = 'Total pembayaran tidak boleh 0'
      self.errors.add(:voluntary_savings_withdrawal_amount, msg)  
      self.errors.add(:cash_amount, msg)  
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
  
  
  def current_week_payment_is_the_highest_priority
    # there are : current week, backlog, and future weeks 
    return if not all_fields_present?
    
    
    if not group_loan_membership.has_cleared_weekly_payment?(group_loan_weekly_task)
      if not is_paying_current_week?   
        msg = "Prioritas Pembayaran: minggu berjalan"
        self.errors.add(:number_of_backlogs, msg ) if number_of_backlogs != 0 
        self.errors.add(:number_of_future_weeks, msg ) if number_of_future_weeks != 0 
      end
    end
    
  end
  
  def no_double_group_loan_weekly_payment
    return if not all_fields_present?
    
    if  is_paying_current_week?  and group_loan_membership.has_cleared_weekly_payment?(group_loan_weekly_task)  
      msg = "Sudah ada pembayaran untuk minggu ini"
      self.errors.add(:is_paying_current_week, msg ) 
    end
  end
  
  def all_fields_present?
    group_loan_membership_id.present?              and   
    group_loan_weekly_task_id.present?             and       
    number_of_backlogs.present?                    and
    is_paying_current_week.present?                and
    is_only_savings.present?                       and
    is_no_payment.present?                         and
    number_of_future_weeks.present?                and
    voluntary_savings_withdrawal_amount.present?   and
    cash_amount.present? 
  end
  
  
  
  def create_group_backlog_payments
    self.group_loan_membership.unpaid_backlogs.limit(self.number_of_backlogs).each do |backlog|
      backlog.create_payment( self ) 
    end
  end
  
  def create_current_week_payment
    current_weekly_responsibility =  group_loan_membership.
                                      remaining_weeks.
                                      where(
                                        :group_loan_weekly_task_id => self.group_loan_weekly_task_id,
                                        :has_clearance => false 
                                      ).first
                                      
    # group_loan_membership.mark_weekly_responsibility_payment( current_weekly_responsibility, self )
    payment_status = nil 
    if self.is_paying_current_week and not self.is_only_savings and not self.is_no_payment
      payment_status =  GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:full_payment]
    elsif not self.is_paying_current_week and  self.is_only_savings and not self.is_no_payment
      payment_status =  GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:only_savings]
    elsif not self.is_paying_current_week and  not self.is_only_savings and  self.is_no_payment
      payment_status =  GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:no_payment_declared]
    end
       
    current_weekly_responsibility.create_weekly_responsibility_clearance( self , payment_status)
    current_weekly_responsibility.assign_group_loan_weekly_payment( self )
  end
  
  # can only be performed if the current week has been paid in the past ( future payment ) 
  # payment_status marked == full_payment 
  def create_only_voluntary_savings_weekly_payment
    current_weekly_responsibility =  group_loan_membership.
                                      remaining_weeks.
                                      where(
                                        :group_loan_weekly_task_id => self.group_loan_weekly_task_id,
                                        :has_clearance => true # cleared in the past  
                                      ).first
                                      
    current_weekly_responsibility.assign_group_loan_weekly_payment( self ) 
  end
  
  def create_future_week_payments
    count = 1 
    group_loan_membership.remaining_weeks.each do |weekly_responsibility|
      # exclude the current week
      next if weekly_responsibility.group_loan_weekly_task_id == self.group_loan_weekly_task_id 
      
      weekly_responsibility.create_weekly_responsibility_clearance( self , GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:full_payment] )
      break if count == number_of_future_weeks
      count += 1 
    end
  end
  
   
  def update_affected_weekly_responsibilities
    self.create_group_backlog_payments  if self.number_of_backlogs != 0 
    self.create_current_week_payment  if self.is_paying_current_week? or self.is_only_savings? or self.is_no_payment?
    self.create_only_voluntary_savings_weekly_payment if self.is_only_voluntary_savings?  
    self.create_future_week_payments  if self.number_of_future_weeks != 0 
  end
  
=begin
  Case: 
  1. Paying full payment for this current week + some extra savings 
  2. Paying only savings for the current week (no money)
  3. Declare that he can't make the payment for the current week
  
  4. The current week is paid by the previous weekly meeting. Hence, he has no obligation to make payment. 
      But, he still makes the payment.
      
      How can the weekly responsibility handles it? 
      weekly_responsibility has clearance_source (signifies which payment that cleared the weekly responsibility).
      @ week 1, the member paid for 3 weeks in advance. 
      @ And, it just happens that on the week 2, this member still wants to make payment. 
        # how can the weekly responsibility cater to this extra payment? 
=end
  
  
  def self.create_object(params)
    new_object                                     = self.new 
    new_object.group_loan_weekly_task_id           = params[:group_loan_weekly_task_id]
    new_object.group_loan_membership_id            = params[:group_loan_membership_id]
    new_object.group_loan_id                       = params[:group_loan_id]
    new_object.number_of_backlogs                  = params[:number_of_backlogs]
    new_object.is_paying_current_week              = params[:is_paying_current_week]
    new_object.is_only_savings                     = params[:is_only_savings]
    new_object.is_no_payment                       = params[:is_no_payment]
    new_object.number_of_future_weeks              = params[:number_of_future_weeks]
    new_object.voluntary_savings_withdrawal_amount = BigDecimal(params[:voluntary_savings_withdrawal_amount])
    new_object.cash_amount                         = BigDecimal(params[:cash_amount])

    new_object.save 
    
    return new_object 
  end
  
  def update_object(params) 
    if self.is_confirmed? 
      self.errors.add(:generic_errors, "Sudah terkonfirmasi")
      return self 
    end
    
    # update pre-confirm
    # update post-confirm 
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
  
  def base_payment_amount
    min_weekly_payment = self.group_loan_membership.group_loan_product.weekly_payment_amount
    total_weeks_paid*min_weekly_payment
  end
  
  def create_savings_entries
    number_of_weeks_paid = self.total_weeks_paid
    
    # create savings withdrawal 
    if voluntary_savings_withdrawal_amount > BigDecimal('0')
      SavingsEntry.create_group_loan_voluntary_savings_withdrawal( self,  self.voluntary_savings_withdrawal_amount )
    end
    
    if not is_only_voluntary_savings?
      #compulsory savings
      (1..number_of_weeks_paid).each do |x|
        SavingsEntry.create_group_loan_compulsory_savings_addition( self,  group_loan_membership.group_loan_product.min_savings)
      end

      #voluntary savings 
      extra_payment = self.cash_amount + self.voluntary_savings_withdrawal_amount  -  base_payment_amount
      if extra_payment > BigDecimal( '0' )
        SavingsEntry.create_group_loan_voluntary_savings_addition( self, extra_payment)
      end

    else

      SavingsEntry.create_group_loan_voluntary_savings_addition( self,  self.cash_amount)
    end
  end
  
  
  
  
  # execute the transaction and past effect 
  def confirm
    return if self.is_confirmed? 
    
    
    self.is_confirmed = true 
    self.confirmation_datetime = DateTime.now 
    self.save
    
    self.update_affected_weekly_responsibilities 
    self.create_transaction_activities
    self.create_savings_entries
  end
  
  
  def delete_object
    return nil if is_confirmed? 
    self.destroy 
  end
  
 
end
