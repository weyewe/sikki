class Member < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  
  has_many :group_loans, :through => :group_loan_memberships 
  has_many :group_loan_memberhips 
  
  has_many :saving_entries 
  has_many :savings_account_payments 
  
  validates_uniqueness_of :id_number 
  validates_presence_of :name, :id_number , :office_id
  
  def self.create_object(params)
    new_object           = self.new
    new_object.name      = params[:name]
    new_object.address   = params[:address]
    new_object.office_id = params[:office_id]
    new_object.id_number = params[:id_number]

    new_object.save
    
    return new_object 
  end
  
  def update_object(params)
    self.name      = params[:name]
    self.address   = params[:address]
    self.id_number = params[:id_number]

    self.save 
  end
  
=begin
  Savings Related 
=end
  def update_total_savings_account
    incoming = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:savings_account],
      :direction => FUND_DIRECTION[:incoming]
    ).sum("amount")   
    
    outgoing = member.savings_entries.where(
      :savings_status => SAVINGS_STATUS[:savings_account],
    ).sum("amount")
    
    self.total_savings_account  = incoming - outgoing 
    self.save
  end
end
