class GroupLoanVoluntarySavingsAddition < ActiveRecord::Base
  attr_accessible :amount, :group_loan_membership_id, :group_loan_id , :employee_id
  validates_presence_of :amount, :group_loan_membership_id , :group_loan_id  , :employee_id
  
  validate :amount_must_not_be_zero
  validate :no_more_than_one_unconfirmed_voluntary_savings_addition
  
  belongs_to :group_loan 
  
  
  belongs_to :group_loan_membership 
  
  has_one :savings_entry 
  
  def all_fields_present?
    amount.present?                                  and   
    group_loan_membership_id.present?                and   
    group_loan_id.present?                           and   
    employee_id.present?    
  end
  
  

  def amount_must_not_be_zero
    return if not all_fields_present?
    
    if amount <= BigDecimal('0')
      self.errors.add(:amount, "Tidak boleh lebih kecil dari 0")
    end
  end
  
   
  def no_more_than_one_unconfirmed_voluntary_savings_addition
    return if not all_fields_present?
    
    if self.class.where(
      :group_loan_membership_id => self.group_loan_membership_id,
      :group_loan_id => self.group_loan_id,
      :is_confirmed => false 
    ).count > 1  
      self.errors.add(:generic_errors, "Ada penarikan tabungan sukarela yang belum dikonfirmasi")
    end
  end
  
  
  
  def self.create_object( params ) 
    new_object = self.new
    new_object.amount = BigDecimal( params[:amount])
    new_object.group_loan_membership_id = params[:group_loan_membership_id]
    new_object.group_loan_id = params[:group_loan_id]
    new_object.employee_id = params[:employee_id]
    
    new_object.save
    return new_object 
  end
  
  def update_object(params)
    return if self.is_confirmed? 
  end
  
  def create_transaction_activities
    member = group_loan_membership.member 
    
    TransactionActivity.create :transaction_source_id => self.id, 
                              :transaction_source_type => self.class.to_s,
                              :cash => self.amount ,
                              :cash_direction => FUND_DIRECTION[:incoming],  
                              :savings =>  BigDecimal("0"),
                              :savings_direction => FUND_DIRECTION[:outgoing], # doesn't matter 
                              :member_id => member.id, 
                              :office_id => member.office_id
                              
  end
  
  def create_savings_entries
    SavingsEntry.create_group_loan_voluntary_savings_addition( self,  self.amount )
  end
  
  
  
  def confirm
    return if self.is_confirmed? 
    
    self.is_confirmed = true 
    self.confirmation_datetime = DateTime.now 
    self.save
    
    
    self.create_transaction_activities
    self.create_savings_entries
    
  end
  
  def delete_object
    return if self.is_confirmed?
    
    self.destroy 
  end
end
