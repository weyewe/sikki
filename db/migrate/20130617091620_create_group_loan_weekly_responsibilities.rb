class CreateGroupLoanWeeklyResponsibilities < ActiveRecord::Migration
  def change
    create_table :group_loan_weekly_responsibilities do |t|
      t.integer :group_loan_membership_id 
      
      t.integer :attendance_status , :default => GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:unmarked]  #options: PRESENT, Absent, Late
      t.integer :payment_status , :default => GROUP_LOAN_WEEKLY_PAYMENT_STATUS[:unmarked]  # options : marked, not marked 
      
      # paid: whether it is only savings or full payment will be deduced by has_clearance
      
      t.integer :group_loan_weekly_task_id , :default => nil 
      
      # clearance_source refers to the payment that cleared this week's responsibility 
      t.string :clearance_source_type , :default => nil 
      t.integer :clearance_source_id   , :default => nil 
      
      # if there is payment made on this week's account
      t.boolean :has_payment,   :default => false 
      # if this week's responsibility is paid  => full payment, only savings, or even no payment 
      t.boolean :has_clearance, :default => false  

      t.timestamps
    end
  end
end
