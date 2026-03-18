class CreateSlots < ActiveRecord::Migration[7.1]
  def change
    create_table :slots do |t|
      t.references :yard, null: false, foreign_key: true
      t.integer :row
      t.integer :column

      t.timestamps
    end
  end
end
