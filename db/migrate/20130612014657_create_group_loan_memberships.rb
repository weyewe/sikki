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
      t.decimal :outstanding_grace_period_amount , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :total_compulsory_savings  , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :total_voluntary_savings , :default        => 0,  :precision => 9, :scale => 2
      
      
      #the initial outstanding is calculated from summing all backlogs 
      
      t.boolean :is_attending_financial_education  , :default => nil 
      t.boolean :is_attending_loan_disbursement , :default => nil 
      
      t.integer :sub_group_loan_id 
      
      
      t.boolean :is_defaultee, :default => false 
      t.decimal :amount_to_be_shared_with_non_defaultee , :default        => 0,  :precision => 9, :scale => 2
      # is_defaultee is to mark whether a particular member is included in the default loan resolution calculation
      
      
      # on group loan closing, the voluntary savings is returned
      # and member takes the $$. However, the field officer will persuade the member 
      # to resave part of $$$ or even taking the next group loan 
      t.decimal :closing_withdrawal_amount , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :closing_savings_amount , :default        => 0,  :precision => 9, :scale => 2
        
      # for history analysis
      # we can count the number of GroupLoanBacklog generated (to understand whether a member is NPL or whatever)
      

      t.timestamps
    end
  end
end
