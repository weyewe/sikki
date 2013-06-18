class CreateGroupLoans < ActiveRecord::Migration
  def change
    create_table :group_loans do |t|
      t.string :name
      t.integer :office_id 
      
      t.boolean :is_started, :default => false 
      t.booelan :is_financial_education_finalized, :default => false 
      t.boolean :is_loan_disbursed, :default => false 
      t.boolean :is_weekly_payment_period_closed, :default => false 
      t.boolean :is_grace_payment_period_closed , :default => false 
      
      t.boolean :is_closed, :default => false
      # t.integer :phase  
=begin Phases: 
  FINANCIAL_EDUCATION => First Filter 
  LOAN_DISBURSEMENT   => Second Filter +
  WEEKLY_PAYMENT      => 
            => Independent payment  => pay for backlog , extra voluntary savings, 
            => normal payment  
  GRACE_PAYMENT     => no interest to be paid 
  DEFAULT_PAYMENT   => auto deduct compulsory savings 
  CLOSE  => port the remaining compulsory savings to voluntary savings 
  
=end
      
      t.decimal :total_default_amount , :precision => 11, :scale => 2 , :default => 0 
      t.decimal :net_income , :precision           => 11, :scale => 2 , :default => 0 
      #net income: can be loss or profit 
      
      t.integer :group_leader_id 
      t.integer :default_payment_resolution_case 

=begin DEFAULT_PAYMENT_CASE
  STANDARD 
  CUSTOM 
=end
      
      t.boolean :is_auto_deduct_admin_fee,        :default => true 
      t.boolean :is_auto_deduct_initial_savings , :default => true 

      t.boolean :is_compulsory_weekly_attendance,:default  => true 

      t.timestamps
    end
  end
end
