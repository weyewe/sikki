# this is the backbone to track savings, any kind of savings
# group_loan_compulsory_savings, group_loan_voluntary_savings 
# normal_savings_account (with interest monthly)
# and even savings withdrawal

class SavingsEntry < ActiveRecord::Base
  attr_accessible :savings_source_id, 
                  :savings_source_type,
                  :amount,
                  :savings_status,
                  :direction,
                  
                  :financial_product_id,
                  :financial_product_type ,
                  :member_id 
                  
  belongs_to :savings_source, :polymorphic => true
  belongs_to :financial_product, :polymorphic => true 
  
  belongs_to :member 
  
  
=begin
  GROUP LOAN related savings 
=end
  def self.create_group_loan_disbursement_initial_compulsory_savings( savings_source )
    group_loan_membership = savings_source.group_loan_membership
    member = group_loan_membership.member 
    
    self.create :savings_source_id => savings_source.id,
                        :savings_source_type => savings_source.class.to_s,
                        :amount => savings_source.group_loan_membership.group_loan_product.initial_savings ,
                        :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
                        :direction => FUND_DIRECTION[:incoming],
                        :financial_product_id => savings_source.group_loan_membership.group_loan_id ,
                        :financial_product_type => savings_source.group_loan_membership.group_loan.class.to_s,
                        :member_id => member.id 
                        
    
    group_loan_membership.update_total_compulsory_savings 
  end

  def self.create_group_loan_voluntary_savings_addition( savings_source, amount)
    group_loan_membership = savings_source.group_loan_membership
    member = group_loan_membership.member
    
    self.create         :savings_source_id      => savings_source.id,
                        :savings_source_type    => savings_source.class.to_s,
                        :amount                 => amount,
                        :savings_status         => SAVINGS_STATUS[:group_loan_voluntary_savings],
                        :direction              => FUND_DIRECTION[:incoming],
                        :financial_product_id   => savings_source.group_loan_id ,
                        :financial_product_type => savings_source.group_loan.class.to_s,
                        :member_id => member.id
    
    group_loan_membership.update_total_voluntary_savings
  end
  
  
  def self.create_group_loan_voluntary_savings_withdrawal( savings_source, amount)
    group_loan_membership = savings_source.group_loan_membership
    member = group_loan_membership.member
    
    self.create         :savings_source_id      => savings_source.id,
                        :savings_source_type    => savings_source.class.to_s,
                        :amount                 => amount,
                        :savings_status         => SAVINGS_STATUS[:group_loan_voluntary_savings],
                        :direction              => FUND_DIRECTION[:outgoing],
                        :financial_product_id   => savings_source.group_loan_id ,
                        :financial_product_type => savings_source.group_loan.class.to_s,
                        :member_id => member.id
    
    
    group_loan_membership.update_total_voluntary_savings
  end
  
  def self.create_group_loan_compulsory_savings_addition( savings_source, amount ) 
    group_loan_membership = savings_source.group_loan_membership
    member = group_loan_membership.member
    
    self.create :savings_source_id => savings_source.id,
                        :savings_source_type => savings_source.class.to_s,
                        :amount => savings_source.group_loan_membership.group_loan_product.min_savings ,
                        :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
                        :direction => FUND_DIRECTION[:incoming],
                        :financial_product_id => savings_source.group_loan_id ,
                        :financial_product_type => savings_source.group_loan.class.to_s,
                        :member_id => member.id
  
    group_loan_membership.update_total_compulsory_savings
  end
  
  def self.create_group_loan_compulsory_savings_withdrawal( savings_source, amount ) 
    group_loan_membership = savings_source.group_loan_membership
    member = group_loan_membership.member
    
    self.create :savings_source_id => savings_source.id,
                        :savings_source_type => savings_source.class.to_s,
                        :amount => savings_source.group_loan_membership.group_loan_product.min_savings ,
                        :savings_status => SAVINGS_STATUS[:group_loan_compulsory_savings],
                        :direction => FUND_DIRECTION[:outgoing],
                        :financial_product_id => savings_source.group_loan_id ,
                        :financial_product_type => savings_source.group_loan.class.to_s,
                        :member_id => member.id
  
    group_loan_membership.update_total_compulsory_savings
  end
  
=begin
  Savings Account related savings : savings withdrawal and savings addition and interest (4% annual), given monthly 
=end
                      
end
