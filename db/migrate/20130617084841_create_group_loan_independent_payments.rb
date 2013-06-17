class CreateGroupLoanIndependentPayments < ActiveRecord::Migration
  def change
    create_table :group_loan_independent_payments do |t|

      t.timestamps
    end
  end
end
