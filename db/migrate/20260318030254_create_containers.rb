class CreateContainers < ActiveRecord::Migration[7.1]
  def change
    create_table :containers do |t|
      t.string :code
      t.references :slot, null: false, foreign_key: true
      t.references :truck, null: false, foreign_key: true

      t.timestamps
    end
  end
end
