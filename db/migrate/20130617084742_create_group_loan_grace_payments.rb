class CreateGroupLoanGracePayments < ActiveRecord::Migration
  def change
    create_table :group_loan_grace_payments do |t|

      t.timestamps
    end
  end
end
