class CreateYards < ActiveRecord::Migration[7.1]
  def change
    create_table :yards do |t|
      t.string :name
      t.integer :rows
      t.integer :columns

      t.timestamps
    end
  end
end
