class CreateGroupLoanIndependentPayments < ActiveRecord::Migration
  def change
    create_table :group_loan_independent_payments do |t|
      t.integer :group_loan_weekly_task_id 
      # find a way so that group_loan_weekly_payment will take place post group_loan_weekly_task_confirmation
      
      t.decimal :voluntary_savings_withdrawal_amount , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :cash_amount , :default        => 0,  :precision => 9, :scale => 2
            
      t.integer :number_of_future_weeks
      t.integer :number_of_backlogs 
      
      t.integer :group_loan_membership_id
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmation_datetime 
      
      t.integer :employee_id # the collector of independent payment 
      
      t.integer :group_loan_id 
      t.integer :group_loan_membership_id 
      

      t.timestamps
    end
  end
end
