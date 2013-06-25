=begin
  Can only be used to pay for 
  1.  voluntary savings with cash     + savings withdrawal
  2.  future weeks payment
  3.  backlog payment 
=end

class GroupLoanIndependentPayment < ActiveRecord::Base
  # attr_accessible :title, :body
  has_one :transaction_activity, :as => :transaction_source 
  
  validate :must_be_attached_to_unconfirmed_weekly_task
  
  belongs_to :group_loan 
  
  def must_be_attached_to_unconfirmed_weekly_task 
    if self.group_loan.group_loan_weekly_tasks.where(:is_confirmed => false).count == 0
      self.errors.add(:generic_errors, "Fase pembayaran cicilan sudah selesai.")
    end
  end
  
  
  def first_unconfirmed_weekly_task
    group_loan.group_loan_weekly_tasks.where(:is_confirmed => false).order("id ASC").first 
  end
  
  
  def self.create_object( params ) 
  end
  
  def update_object( params ) 
  end
  
  
end
