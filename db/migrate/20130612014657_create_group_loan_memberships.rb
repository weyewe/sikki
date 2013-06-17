class CreateGroupLoanMemberships < ActiveRecord::Migration
  def change
    create_table :group_loan_memberships do |t|
      t.integer :member_id 
      t.integer :group_loan_id 
      
      t.boolean :is_active , :default => true 
      t.integer :deactivation_status 
=begin
Deactivation Status 
1. absent @ financial education
2. absent @ loan disbursement 
=end
      
      t.boolean :attended_financial_education , :default => false 
      t.boolean :attended_loan_disbursement , :default => false 
      
      t.integer :sub_group_loan_id 
      
      
      t.boolean :is_defaultee, :default => false 

      t.timestamps
    end
  end
end
