class CreateSubGroupLoans < ActiveRecord::Migration
  def change
    create_table :sub_group_loans do |t|
      t.integer :group_loan_id
      t.string :name 
      t.integer :sub_group_leader_id 
      
      t.decimal :sub_group_total_default_payment_amount, :precision => 10, :scale => 2 , :default => 0 
      
      # total default amount paid by this group (50% default value.. but, what if all the members are default)
      t.decimal :sub_group_default_payment_contribution_amount, :precision => 10, :scale => 2 , :default => 0 
      t.decimal :actual_sub_group_default_payment_contribution_amount, :precision => 10, :scale => 2 , :default => 0

      t.timestamps
    end
  end
end
