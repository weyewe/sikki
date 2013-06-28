class GroupLoanSubcription < ActiveRecord::Base
  belongs_to :group_loan_product 
  belongs_to :group_loan_membership
  validates_presence_of :group_loan_product_id, :group_loan_membership_id 
  
  validate :allow_update_if_group_loan_not_started 
  
  
  def all_fields_present?
    group_loan_product_id.present? and 
    group_loan_membership_id.present? 
  end
  
  def allow_update_if_group_loan_not_started
    return  if not all_fields_present? 
    
    if self.persisted? and group_loan_membership.group_loan.is_started? 
      self.errors.add(:generic_errors, "Pinjaman Group sudah berjalan")
    end
  end
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.group_loan_product_id = params[:group_loan_product_id]
    new_object.group_loan_membership_id = params[:group_loan_membership_id]
    new_object.save
    
    return new_object
  end
  
  
  def update_object( params ) 
     
    self.group_loan_product_id = params[:group_loan_product_id] 
    self.save 
    
    return self 
  end
  
  def delete_object( params ) 
    allow_update_if_group_loan_not_started # validation 
    return if self.errors.size != 0
    
    self.destroy 
  end
end
