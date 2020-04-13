class CreatePositions < ActiveRecord::Migration[6.0]
  def change
    create_table :positions do |t|
      t.string :type
      t.float :request, default: 0
      t.float :plan, default: 0
      t.float :produced, default: 0
      t.float :delivered, default: 0
      t.references :bid, null: false, foreign_key: true

      t.timestamps
    end
  end
end
