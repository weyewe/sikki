class CreateGroupLoanPortVoluntarySavings < ActiveRecord::Migration
  def change
    create_table :group_loan_port_voluntary_savings do |t|

      t.integer :group_loan_membership_id 
      t.decimal :amount , :default        => 0,  :precision => 9, :scale => 2
      t.timestamps
    end
  end
end
