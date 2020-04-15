class Region < ApplicationRecord
  has_many :bids
  has_many :reports

  def to_s
    "#{code} #{name}"
  end
end
