class GroupLoanDefaultPayment < ActiveRecord::Base
  attr_accessible :group_loan_membership_id 
  has_one :transaction_activity, :as => :transaction_source 
  
  def self.rounding_up(amount,  nearest_amount ) 
    total = amount
    # total_amount

    multiplication_of_500 = ( total.to_i/nearest_amount.to_i ) .to_i
    remnant = (total.to_i%nearest_amount.to_i)
    if remnant > 0  
      return  nearest_amount *( multiplication_of_500 + 1 )
    else
      return nearest_amount *( multiplication_of_500  )
    end  
  end
  
  def calculate_defaultee_standard_resolution
    glm = self.group_loan_membership 
    total_compulsory_savings = glm.total_compulsory_savings
    total_voluntary_savings = glm.total_voluntary_savings
    
    total_amount = self.compulsory_savings_deduction_amount + 
                  self.voluntary_savings_deduction_amount
    
    rounded_up_total_amount  = DefaultPayment.rounding_up( total_amount, DEFAULT_PAYMENT_ROUND_UP_VALUE ) 
    
    remnant = rounded_up_total_amount  - self.compulsory_savings_deduction_amount 
    
    if remnant <= total_voluntary_savings 
      self.voluntary_savings_deduction_amount = remnant
    else
      self.voluntary_savings_deduction_amount = total_voluntary_savings
    end
    
    
    self.standard_resolution_amount = rounded_up_total_amount 
     
    self.save 
  end
  
  def calculate_non_defaultee_standard_resolution
    glm = self.group_loan_membership 
    total_compulsory_savings = glm.total_compulsory_savings
    total_voluntary_savings = glm.total_voluntary_savings
    
    total_amount = self.amount_sub_group_share + 
                  self.amount_group_share
                  
    rounded_up_total_amount  = DefaultPayment.rounding_up( total_amount , DEFAULT_PAYMENT_ROUND_UP_VALUE) 
    
    
    if rounded_up_total_amount <= total_compulsory_savings
      self.compulsory_savings_deduction_amount = rounded_up_total_amount 
    else
      self.compulsory_savings_deduction_amount = total_compulsory_savings
    end
    
    self.voluntary_savings_deduction_amount  = BigDecimal("0") # office won't deduct non-defaultee voluntary savings
   
    self.standard_resolution_amount = rounded_up_total_amount
    
    
    self.save 
  end
  
  
  
  
  def assign_custom_resolution_amount( amount ) 
    if self.is_defaultee?
      total_group_loan_savings = group_loan_membership.total_compulsory_savings + group_loan_membership.total_voluntary_savings
      if custom_resolution_amount > total_group_loan_savings
        self.errors.add(:custom_resolution_amount, "Tidak boleh lebih besar dari tabungan: #{total_group_loan_savings}")
        return self
      end
      
      if custom_resolution_amount > compulsory_savings_deduction_amount
        self.custom_compulsory_savings_deduction_amount = compulsory_savings_deduction_amount
        self.custom_voluntary_savings_deduction_amount = custom_resolution_amount - compulsory_savings_deduction_amount
        self.save 
      else
        self.custom_compulsory_savings_deduction_amount = custom_resolution_amount
        self.custom_voluntary_savings_deduction_amount = BigDecimal('0')
        self.save
      end
    else
      if custom_resolution_amount > compulsory_savings_deduction_amount
        self.errors.add(:custom_resolution_amount, "Tidak boleh lebih besar dari tabungan wajib: #{compulsory_savings_deduction_amount}")
        return self 
      else
        self.custom_compulsory_savings_deduction_amount = custom_resolution_amount
        self.custom_voluntary_savings_deduction_amount = BigDecimal('0')
        self.save
      end
    end
  end
  
  
  def execute_standard_payment 
    SavingsEntry.create_group_loan_compulsory_savings_withdrawal( self, self.compulsory_savings_deduction_amount ) 
    
    # if it is non_defaultee, the voluntary_savings_deduction_amount will be 0 
    if self.voluntary_savings_deduction_amount > BigDecimal('0')
      SavingsEntry.create_group_loan_voluntary_savings_withdrawal( self, self.voluntary_savings_deduction_amount ) 
    end
  end
  
  def execute_custom_payment
    SavingsEntry.create_group_loan_compulsory_savings_withdrawal( self, self.custom_compulsory_savings_deduction_amount ) 
    
    # if it is non_defaultee, the voluntary_savings_deduction_amount will be 0 
    if self.custom_voluntary_savings_deduction_amount > BigDecimal('0')
      SavingsEntry.create_group_loan_voluntary_savings_withdrawal( self, self.custom_voluntary_savings_deduction_amount ) 
    end
  end
end
