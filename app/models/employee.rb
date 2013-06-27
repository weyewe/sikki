class Employee < ActiveRecord::Base
  belongs_to :office 
  
  def self.create_object(params)
    new_object           = self.new
    new_object.name      = params[:name]
    new_object.office_id = params[:office_id]
    

    new_object.save
    
    return new_object 
  end
  
  def update_object(params)
    self.name      = params[:name]
    self.office_id = params[:office_id]

    self.save 
  end
  
end
