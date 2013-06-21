class CreateGroupLoanDefaultPayments < ActiveRecord::Migration
  def change
    create_table :group_loan_default_payments do |t|
      t.integer :group_loan_membership_id 
      
      # if this member is defaultee
      t.decimal :amount_to_be_shared_with_non_defaultee,  :precision => 10, :scale => 2 , :default => 0
      
      
      
      t.decimal :amount_sub_group_share, :precision => 10, :scale => 2 , :default => 0 
      t.decimal :amount_group_share,  :precision => 10, :scale => 2 , :default => 0 
      
      t.decimal :compulsory_savings_deduction_amount,  :precision => 10, :scale => 2 , :default => 0 
      t.decimal :voluntary_savings_deduction_amount,  :precision => 10, :scale => 2 , :default => 0 
      # voluntary savings can only be deducted on custom default resolution 
      
      
      
      # total suggested amount, after rounding up to 500 rupiah denomination ( default amount ) 
      t.decimal :standard_resolution_amount ,  :precision => 10, :scale => 2 , :default => 0
      #total_amount = sub_group_share + group_share 
      t.decimal :custom_resolution_amount ,  :precision => 10, :scale => 2 , :default => 0 
      
      
      
      # on the group resolution 
      t.decimal :amount_paid ,  :precision => 10, :scale => 2 , :default => 0 
      #depending on the resolution type: custom or standard
      
      
      t.decimal :amount_assumed_by_office,  :precision => 10, :scale => 2 , :default => 0 

      t.timestamps
    end
  end
end
