class CreateGroupLoanBacklogs < ActiveRecord::Migration
  def change
    create_table :group_loan_backlogs do |t|
      t.integer :group_loan_membership_id
      t.integer :group_loan_id 
      
      t.boolean :is_paid , :default => false 
      
      t.timestamps
    end
  end
end
