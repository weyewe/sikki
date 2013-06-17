class GroupLoanSubcription < ActiveRecord::Base
  belongs_to :group_loan_product 
  belongs_to :group_loan_membership
  validates_presence_of :group_loan_product_id, :group_loan_membership_id 
  
  validate :all_group_loan_products_must_have_equal_duration 
  
  def all_group_loan_products_must_have_equal_duration
    if group_loan_product_id.present? and group_loan_membership_id.present?
      group_loan = self.group_loan_membership.group_loan 
      total_weeks_array = []
      
      group_loan.active_group_loan_memberships.each do |glm|
        group_loan_product = glm.group_loan_product
        next if group_loan_product.nil?
        
        total_weeks_array = group_loan_product.total_weeks 
      end
      
      if total_weeks_array.uniq.length != 1 
        errors.add(:group_loan_product_id, "Dalam 1 grup, jumlah minggu cicilan harus sama")
      end
      
      if total_weeks_array.uniq.length == 1  and total_weeks_array.uniq.first != group_loan_product.total_weeks
        errors.add(:group_loan_product_id, "Dalam 1 grup, jumlah minggu cicilan harus sama")
      end
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
    return nil if group_loan_membership.group_loan.is_started? 
    self.group_loan_product_id = params[:group_loan_product_id] 
    self.save 
    
    return self 
  end
  
  def delete_object( params ) 
    return nil if group_loan_membership.group_loan.is_started? 
    
    self.destroy 
  end
end
