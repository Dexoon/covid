class CreateRegions < ActiveRecord::Migration[6.0]
  def change
    create_table :regions do |t|
      t.string :name
      t.integer :code
      t.integer :chat_id

      t.timestamps
    end
  end
end
