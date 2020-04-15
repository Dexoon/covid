class User < ApplicationRecord
  def to_s
    if username.nil?
      "<a href=\"tg://user?id=#{tg_id}\">#{name}</a>"
    else
      "@#{username}"
    end
  end
end
