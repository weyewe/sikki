class CreateSubGroupLoans < ActiveRecord::Migration
  def change
    create_table :sub_group_loans do |t|

      t.timestamps
    end
  end
end
