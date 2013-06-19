class CreateGroupLoanVoluntarySavingsWithdrawals < ActiveRecord::Migration
  def change
    create_table :group_loan_voluntary_savings_withdrawals do |t|

      t.timestamps
    end
  end
end
