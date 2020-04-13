json.extract! user, :id, :type, :name, :username, :tg_id, :created_at, :updated_at
json.url user_url(user, format: :json)
