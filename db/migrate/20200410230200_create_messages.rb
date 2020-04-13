class CreateMessages < ActiveRecord::Migration[6.0]
  def change
    create_table :messages do |t|
      t.string :type
      t.integer :chat_id, limit: 8
      t.integer :message_id
      t.references :archmessage, polymorphic: true, index: true

      t.timestamps
    end
  end
end
