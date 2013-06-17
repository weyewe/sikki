class CreateTransactionActivities < ActiveRecord::Migration
  def change
    create_table :transaction_activities do |t|
      t.integer :transaction_source_id 
      t.string :transaction_source_type 

      t.timestamps
    end
  end
end
