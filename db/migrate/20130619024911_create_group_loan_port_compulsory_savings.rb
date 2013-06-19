class CreateGroupLoanPortCompulsorySavings < ActiveRecord::Migration
  def change
    create_table :group_loan_port_compulsory_savings do |t|

      t.timestamps
    end
  end
end
