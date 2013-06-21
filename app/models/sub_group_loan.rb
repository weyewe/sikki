class SubGroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :group_loan 
  has_many :group_loan_memberships 
  
  validates_presence_of :name, :group_loan_id 
  
  
  def self.create_object( params ) 
    new_object               = self.new 
    new_object.group_loan_id = params[:group_loan_id]
    new_object.name          = params[:name]

    new_object.save 
    return new_object
  end
  
  def update_object( params ) 
    return nil if  self.group_loan.is_started?    
    
    self.group_loan_id = params[:group_loan_id]
    self.name          = params[:name]

    self.save 
    return self
  end
  
  def delete_object
    return nil if   self.group_loan.is_started?   
    self.destroy 
  end
  
  def active_group_loan_memberships 
    self.group_loan_memberships.where(:is_active => true )
  end
  
  def update_sub_group_default_payment_contribution#(total_to_be_shared)
    # sub_group_contribution_amount = total_to_be_shared * ( 50.0/100.0)
    
    active_subgroup_glm = self.active_group_loan_memberships.includes(:default_payment)
    
    active_subgroup_glm_id_list  = active_subgroup_glm.map { |x| x.id  }
    
    sub_group_amount_to_be_shared = BigDecimal("0")
   
    active_subgroup_glm.each do |glm|
      sub_group_amount_to_be_shared = glm.amount_to_be_shared_with_non_defaultee
    end
    
    self.sub_group_default_payment_contribution_amount = sub_group_amount_to_be_shared
    self.save
    
    sub_group_contribution_amount = sub_group_amount_to_be_shared * ( 50.0/100.0)
    
    non_default_payment = []
    
    
    
    number_of_non_defaultee_in_subgroup = active_subgroup_glm.where(:is_defaultee => false )
    
    if number_of_non_defaultee_in_subgroup  >  0 
      sub_group_contribution_per_non_defaultee = sub_group_contribution_amount / number_of_non_defaultee_in_subgroup
      
      active_subgroup_glm.where(:is_defaultee => false) .each do |glm|
        default_payment = glm.default_payment 
        default_payment.amount_sub_group_share = sub_group_contribution_per_non_defaultee
        default_payment.save
      end
    end
  end
end
