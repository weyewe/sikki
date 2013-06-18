class GroupLoanMembership < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office
  belongs_to :member 
  belongs_to :group_loan 
  belongs_to :sub_group_loan 
  
  has_one :group_loan_subcription
  has_one :group_loan_product, :through => :group_loan_subcription 
  
  has_one :group_loan_default_payment  #checked  
  has_one :group_loan_disbursement  #checked 
  has_many :group_loan_weekly_payments   # we need the model. A weekly task 
  # => can be paid through backlog payment, weekly payment, or independent payment 
  has_many :group_loan_independent_payments
  has_many :group_loan_grace_payments
  has_many :group_loan_weekly_responsibilities
  
  def self.create_object( params ) 
    new_object = self.new 
    new_object.group_loan_id      = params[:group_loan_id] 
    new_object.sub_group_loan_id  = params[:sub_group_loan_id]
    new_object.member_id          = params[:member_id]
    new_object.save
    
    return new_object 
  end
  
  def update_object( params ) 
    return nil if self.group_loan.is_started? 
    
    self.sub_group_loan_id  = params[:sub_group_loan_id] 
    self.member_id = params[:member_id]
    self.save
  end
  
  def delete_object
    return nil if self.group_loan.is_started? 
    
    if not self.group_loan_subcription.nil?
      self.group_loan_subcription.destroy
    end
    
    self.destroy 
  end
  
  
  def mark_financial_education_attendance( params )
    if self.group_loan.is_financial_education_finalized? 
      errors.add(:is_attending_financial_education, "Tidak bisa edit. Pendidikan keuangan sudah difinalisasi")
      return 
    end
    
    self.is_attending_financial_education = params[:is_attending_financial_education]
    self.save 
  end
  
  
end
