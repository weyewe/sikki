class GroupLoanDefaultPayment < ActiveRecord::Base
  # attr_accessible :title, :body
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
  
end
