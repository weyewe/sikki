class CreateGroupLoanProducts < ActiveRecord::Migration
  def change
    create_table :group_loan_products do |t|
      t.string :name 
      
      t.decimal :principal , :default        => 0,  :precision => 9, :scale => 2 # 10^7 == 10 million ( max value )
      t.decimal :interest,    :default       => 0, :precision => 9, :scale => 2
      t.decimal :min_savings, :default       => 0, :precision => 9, :scale => 2
      
      # The setup deduction 
      t.decimal :admin_fee,   :default       => 0,  :precision => 9, :scale => 2
      t.decimal :initial_savings ,  :default => 0, :precision => 9, :scale => 2

      
      t.integer :total_weeks
      t.integer :office_id
      

      t.timestamps
    end
  end
end
