class CreateBids < ActiveRecord::Migration[6.0]
  def change
    create_table :bids do |t|
      t.references :region, null: false, foreign_key: true
      t.text :contact_info
      t.string :aasm_state
      t.string :type

      t.timestamps
    end
  end
end
