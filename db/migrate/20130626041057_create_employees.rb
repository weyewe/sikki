class CreateEmployees < ActiveRecord::Migration
  def change
    create_table :employees do |t|
      t.integer :office_id 
      
      
      t.string :name 
      
      t.timestamps
    end
  end
end
