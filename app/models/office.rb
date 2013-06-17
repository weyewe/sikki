class Office < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :users, :through => :job_attachments 
  has_many :job_attachments 
  
  has_many :members 
  
  has_many :group_loan_products
  has_many :group_loans 
  has_many :group_loan_memberships 
end
