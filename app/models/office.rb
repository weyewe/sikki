class Office < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :users, :through => :job_attachments 
  has_many :job_attachments 
  
  has_many :members 
  has_many :employees 
  
  has_many :group_loan_products
  has_many :group_loans 
  has_many :group_loan_memberships 
  
  def self.create_object(params)
    new_object = self.new
    new_object.name = params[:name]
    new_object.address = params[:address]
    
    new_object.save
    
    return new_object 
  end
  
  def update_object(params)
    self.name    = params[:name]
    self.address = params[:address]
    
    self.save 
  end
end
