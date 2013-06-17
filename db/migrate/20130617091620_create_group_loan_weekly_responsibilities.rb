class CreateGroupLoanWeeklyResponsibilities < ActiveRecord::Migration
  def change
    create_table :group_loan_weekly_responsibilities do |t|
      t.integer :group_loan_membership_id 
      
      t.integer :attendance_status , :default => nil  #options: PRESENT, Absent, Late
      t.integer :payment_status , :default => nil  # options : no payment, paid
      
      # paid: whether it is only savings or full payment will be deduced by has_clearance
      
      t.integer :group_loan_weekly_payment_id , :default => nil 
      
      # clearance_source refers to the payment that cleared this week's responsibility 
      t.string :clearance_source_type , :default => nil 
      t.integer :clearance_source_id   , :default => nil 
      
      # if there is payment made on this week's account
      t.boolean :has_payment,   :default => nil 
      # if this week's responsibility is paid 
      t.boolean :has_clearance, :default => false  

      t.timestamps
    end
  end
end
