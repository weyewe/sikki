class GroupLoanDisbursement < ActiveRecord::Base
  attr_accessible :group_loan_membership_id 
  has_many :transaction_activities, :as => :transaction_source 
  has_many :savings_entries, :as => :savings_source 
  
  validates_uniqueness_of :group_loan_membership_id 
  
  after_create :create_transaction_activity , :create_initial_compulsory_savings
  
  
  def create_transaction_activity 
    # delta_savings => customer perspective 
    # delta_cash => company perspective  
    
    t.boolean :is_auto_deduct_admin_fee,        :default => true 
    t.boolean :is_auto_deduct_initial_savings , :default => true
    
    if group_loan.is_auto_deduct_admin_fee and group_loan.is_auto_deduct_initial_savings
    end
    
    ## the main use case is auto deduct admin fee and auto deduct initial savings 
    # if not group_loan.is_auto_deduct_admin_fee and group_loan.is_auto_deduct_initial_savings
    # end
    # 
    # if group_loan.is_auto_deduct_admin_fee and not group_loan.is_auto_deduct_initial_savings
    # end
    # 
    # if not group_loan.is_auto_deduct_admin_fee and not group_loan.is_auto_deduct_initial_savings
    # end
    
     
    # COMPANY's perspective
    # on group loan disbursement, there are 3 activities: 
    # company disbursed the $$$
    # member pays the admin fee
    # member pays the initial_compulsory_savings 
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => group_loan_membership.group_loan_product.disbursed_principal ,
                              :cash_direction => FUND_DIRECTION[:outgoing],
                              :savings_direction => FUND_DIRECTION[:incoming]
                              :savings => BigDecimal('0')
    
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => group_loan_membership.group_loan_product.admin_fee   ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings_direction => FUND_DIRECTION[:incoming]
                              :savings => BigDecimal('0')
                              
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => group_loan_membership.group_loan_product.initial_savings   ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings_direction => FUND_DIRECTION[:incoming]
                              :savings => BigDecimal('0')
  end
  
  def create_initial_compulsory_savings 
    SavingsEntry.create :savings_source_id => self.id,
                        :savings_source_type => self.class.to_s,
                        :amount => group_loan_membership.group_loan_product.initial_savings ,
                        :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
                        :direction => FUND_DIRECTION[:incoming],
                        :financial_product_id => self.group_loan_membership.group_loan_id ,
                        :financial_product_type => self.group_loan_membership.group_loan.to_s
  end
  
end
