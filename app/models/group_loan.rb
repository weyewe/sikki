class GroupLoan < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :members, :through => :group_loan_memberships 
  has_many :group_loan_memberships 
  has_many :sub_group_loans 
  
  has_many :group_loan_weekly_tasks # weekly payment, weekly attendance  
  validates_presence_of :office_id , :name,
                          :is_auto_deduct_admin_fee,
                          :is_auto_deduct_initial_savings, 
                          :is_compulsory_weekly_attendance
                          
  validates_uniqueness_of :name 
  
  
  def self.create_object( office, params)
    new_object = self.new
    new_object.office_id = office.id 
    
    new_object.name                            = params[:name]
    new_object.is_auto_deduct_admin_fee        = params[:is_auto_deduct_admin_fee]
    new_object.is_auto_deduct_initial_savings  = params[:is_auto_deduct_initial_savings]
    new_object.is_compulsory_weekly_attendance = params[:is_compulsory_weekly_attendance]
    
    new_object.save
    
    return new_object 
  end
  
  def self.update_object( params ) 
    return nil if self.is_started?  
      
    self.name                            = params[:name]
    self.is_auto_deduct_admin_fee        = params[:is_auto_deduct_admin_fee]
    self.is_auto_deduct_initial_savings  = params[:is_auto_deduct_initial_savings]
    self.is_compulsory_weekly_attendance = params[:is_compulsory_weekly_attendance]
    
    self.save
    
    return self
  end
  
  
  def active_group_loan_memberships
    self.group_loan_memberships.where(:is_active => true )
  end
   
  
end