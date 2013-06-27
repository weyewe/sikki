class CreateSavingsAccountWithdrawals < ActiveRecord::Migration
  def change
    create_table :savings_account_withdrawals do |t|
      t.integer :member_id 
      t.decimal :amount , :default        => 0,  :precision => 9, :scale => 2
      
      t.integer :employee_id 
      
      t.boolean :is_confirmed , :default => false 
      t.datetime :confirmation_datetime
      
      t.timestamps
    end
  end
end
