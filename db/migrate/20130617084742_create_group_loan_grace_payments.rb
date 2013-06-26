class CreateGroupLoanGracePayments < ActiveRecord::Migration
  def change
    create_table :group_loan_grace_payments do |t|
      
      t.integer :group_loan_membership_id 
      t.integer :group_loan_id 
      
      t.decimal :voluntary_savings_withdrawal_amount , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :cash_amount , :default        => 0,  :precision => 9, :scale => 2
      
      t.decimal :default_payment_amount , :default        => 0,  :precision => 9, :scale => 2
      
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmation_datetime  # automated 
      
      t.datetime :collection_datetime
      t.integer :employee_id # written on the form (name) 
      
      

      t.timestamps
    end
  end
end
