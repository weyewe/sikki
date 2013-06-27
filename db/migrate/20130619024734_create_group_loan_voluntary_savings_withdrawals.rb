class CreateGroupLoanVoluntarySavingsWithdrawals < ActiveRecord::Migration
  def change
    create_table :group_loan_voluntary_savings_withdrawals do |t|
      
      t.integer :group_loan_membership_id 
      t.integer :group_loan_id 
      t.integer :employee_id 
      
      t.decimal :amount , :default        => 0,  :precision => 9, :scale => 2
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmation_datetime 

      t.timestamps
    end
  end
end
