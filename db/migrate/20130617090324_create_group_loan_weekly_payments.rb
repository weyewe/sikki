class CreateGroupLoanWeeklyPayments < ActiveRecord::Migration
  def change
    create_table :group_loan_weekly_payments do |t|
      
      t.integer :group_loan_weekly_task_id           
      t.integer :group_loan_membership_id            
      t.integer :number_of_backlogs                  
      t.boolean :is_paying_current_week              , :default => true 
      t.boolean :is_only_savings                      , :default => false         
      t.boolean :is_no_payment                        , :default => false 
      
        
      t.decimal :voluntary_savings_withdrawal_amount , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :cash_amount , :default        => 0,  :precision => 9, :scale => 2
            
      t.integer :number_of_future_weeks                    
      
      

      t.timestamps
    end
  end
end
