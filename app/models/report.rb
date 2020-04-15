class Report < ApplicationRecord
  belongs_to :region
  after_create :write_to_sheets

  def write_to_sheets

  end

  def to_s
    "\#заказ#{order}
    #{region}
    #{product.each_slice(2).to_a.map { |x| x.join(': ') }.join("\n")}"
  end

  def to_line
    [
        "#{region.code},#{order}",
        "#{region}",
        "#{order}",
        "#{product.each_slice(2).to_a.map { |x| x.join(':') }.join(", ")}"
    ] + photo
  end
end
