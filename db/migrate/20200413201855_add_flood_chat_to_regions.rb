class AddFloodChatToRegions < ActiveRecord::Migration[6.0]
  def change
    add_column :regions, :flood_chat_id, :integer, limit:8
    change_column :regions, :chat_id, :integer, limit:8
  end
end
