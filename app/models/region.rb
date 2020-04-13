class Region < ApplicationRecord
  has_many :bids

  def to_s
    "#{code} #{name}"
  end
end
