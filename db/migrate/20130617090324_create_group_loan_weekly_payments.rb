class CreateGroupLoanWeeklyPayments < ActiveRecord::Migration
  def change
    create_table :group_loan_weekly_payments do |t|

      t.timestamps
    end
  end
end
