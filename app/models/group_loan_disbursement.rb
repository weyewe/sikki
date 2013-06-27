class GroupLoanDisbursement < ActiveRecord::Base
  attr_accessible :group_loan_membership_id 
  has_many :transaction_activities, :as => :transaction_source 
  has_many :savings_entries, :as => :savings_source 
  
  validates_uniqueness_of :group_loan_membership_id 
  
  after_create :create_transaction_activities , :create_initial_compulsory_savings
  
  
  def create_transaction_activities 
    # delta_savings => customer perspective 
    # delta_cash => company perspective  
    
  
    # if group_loan.is_auto_deduct_admin_fee and group_loan.is_auto_deduct_initial_savings
    # end
    
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
    
    member = group_loan_membership.member 
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => group_loan_membership.group_loan_product.disbursed_principal ,
                              :cash_direction => FUND_DIRECTION[:outgoing],
                              :savings_direction => FUND_DIRECTION[:incoming],
                              :savings => BigDecimal('0'),
                              :member_id => member.id, 
                              :office_id => member.office_id 
    
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => group_loan_membership.group_loan_product.admin_fee   ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings_direction => FUND_DIRECTION[:incoming],
                              :savings => BigDecimal('0'),
                              :member_id => member.id, 
                              :office_id => member.office_id
                              
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => group_loan_membership.group_loan_product.initial_savings   ,
                              :cash_direction => FUND_DIRECTION[:incoming],
                              :savings_direction => FUND_DIRECTION[:incoming],
                              :savings => BigDecimal('0'),
                              :member_id => member.id, 
                              :office_id => member.office_id
  end
  
  def create_initial_compulsory_savings 
    SavingsEntry.create_group_loan_disbursement_initial_compulsory_savings( self )
    
  end
  
end
