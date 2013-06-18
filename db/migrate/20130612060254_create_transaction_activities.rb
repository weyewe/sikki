class CreateTransactionActivities < ActiveRecord::Migration
  def change
    create_table :transaction_activities do |t|
      t.integer :transaction_source_id 
      t.string :transaction_source_type 
      
      t.decimal :incoming_cash , :default        => 0,  :precision => 9, :scale => 2
      t.decimal :incoming_savings, :default        => 0,  :precision => 9, :scale => 2

      t.timestamps
    end
  end
end
