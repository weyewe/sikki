class CreateMembers < ActiveRecord::Migration
  def change
    create_table :members do |t|
      
      t.string :name 
      t.text :address 
      t.integer :office_id 
      
      t.string :id_number 
      
      t.decimal :total_savings_account , :default        => 0,  :precision => 12, :scale => 2

      t.timestamps
    end
  end
end
