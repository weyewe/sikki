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
end
