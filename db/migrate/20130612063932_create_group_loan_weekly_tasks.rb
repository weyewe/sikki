class CreateGroupLoanWeeklyTasks < ActiveRecord::Migration
  def change
    create_table :group_loan_weekly_tasks do |t|
      
      t.integer :group_loan_id 
      t.integer :week_number 
      
      t.datetime :collection_datetime
      t.integer :employee_id   # the one responsible for extracting weekly payment
      
      
      t.boolean :is_confirmed, :default => false 
      t.datetime :confirmation_datetime
      
     
      
      # the amount of $ to be passed is correct
      t.decimal :total_amount_collected,  :precision => 12, :scale => 2 , :default => 0 
      
      
      
      
       
      
      t.timestamps
    end
  end
end
