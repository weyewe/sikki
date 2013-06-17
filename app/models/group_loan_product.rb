class GroupLoanProduct < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :group_loans 
  
  validates_presence_of :office_id 
  
  def self.create_object( office, params) 
    new_object = 
  end
end
