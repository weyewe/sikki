class CreateGroupLoanWeeklyTasks < ActiveRecord::Migration
  def change
    create_table :group_loan_weekly_tasks do |t|
      
      t.integer :group_loan_id 
      t.integer :week_number 
      
      t.boolean :is_closed, :default => false  
      
      t.date :collection_date 
      t.time :collection_time_start 
      t.time :collection_time_end
      
      # the amount of $ to be passed is correct
      t.decimal :total_amount_collected,  :precision => 12, :scale => 2 , :default => 0 
      
      
      t.timestamps
    end
  end
end
