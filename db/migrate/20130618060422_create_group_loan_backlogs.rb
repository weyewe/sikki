class CreateGroupLoanBacklogs < ActiveRecord::Migration
  def change
    create_table :group_loan_backlogs do |t|
      t.integer :group_loan_membership_id
      t.integer :group_loan_id 
      t.integer :group_loan_weekly_responsibility_id 
      
      t.boolean :is_paid , :default => false 
      
      
      t.integer :backlog_clearance_source_id 
      t.string :backlog_clearance_source_type 
      
      t.timestamps
    end
  end
end
