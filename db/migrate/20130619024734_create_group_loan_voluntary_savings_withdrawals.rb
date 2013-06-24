class CreateGroupLoanVoluntarySavingsWithdrawals < ActiveRecord::Migration
  def change
    create_table :group_loan_voluntary_savings_withdrawals do |t|
      t.integer :withdrawal_case , :default => GROUP_LOAN_VOLUNTARY_SAVINGS_WITHDRAWAL_CASE[:normal]
      
      t.integer :group_loan_membership_id 
      t.decimal :amount , :default        => 0,  :precision => 9, :scale => 2

      t.timestamps
    end
  end
end
