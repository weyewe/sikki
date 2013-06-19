class CreateGroupLoanPortVoluntarySavings < ActiveRecord::Migration
  def change
    create_table :group_loan_port_voluntary_savings do |t|

      t.timestamps
    end
  end
end
