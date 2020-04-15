class CreateReports < ActiveRecord::Migration[6.0]
  def change
    create_table :reports do |t|
      t.integer :order
      t.references :region, null: false, foreign_key: true
      t.string :product, array: true, default: []
      t.string :photo, array: true, default: []

      t.timestamps
    end
  end
end
