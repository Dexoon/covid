class Position < ApplicationRecord
  belongs_to :bid, touch: true
  has_many :messages, as: :archmessage

  def self.name
    to_s
  end

  def name
    self.class.name
  end

  def to_s
    "#{self.class.name} Необх:#{request} план:#{plan} произв:#{produced} дост;#{delivered}"
  end
end
class DocSupply < Position

end
class MakerSupply < Position
  #after_create :send_auxiliary_message
end

class Shield < DocSupply
  def self.name
    "Щитки"
  end

end
class Hairpin < DocSupply
  def self.name
    "Заколки"
  end

end

class Box < DocSupply
  def self.name
    "Боксы"
  end

end
class MaskAdapter < DocSupply
  def self.name
    "Адаптеры"
  end

end

class PLA < MakerSupply

end
class PETG < MakerSupply

end
class ABS < MakerSupply

end
class SBS < MakerSupply

end
class Polyethylene < MakerSupply
  def self.name
    "ПЭТ"
  end

end