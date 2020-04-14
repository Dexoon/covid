class Bid < ApplicationRecord
  belongs_to :region
  has_many :positions
  has_many :messages, as: :archmessage
  after_commit :update_messages
  accepts_nested_attributes_for :positions

  def update_messages
    messages.each do |msg|
      msg.refresh
    end
  end

  def to_text
    text = "Статус:##{aasm_state}\n#{contact_info}\nРегион: #{region}\n\n"
    text += positions.map(&:to_s).join("\n")
    text
  end

  def to_admin_text
    to_text + "\n#{ENV['URL']}/bids/#{id}/edit"
  end

  include AASM
  aasm do
    state :unanswered, initial: true, after_enter: :send_auxiliary_message
    state :confirmed, after_enter: :send_auxiliary_message
    state :in_production, after_enter: :send_auxiliary_message
    state :ready
    state :shipped, after_enter: :send_auxiliary_message
    state :delivery, :refused
    event :confirm do
      transitions from: :unanswered, to: :confirmed
    end
    event :next do
      transitions from: :unanswered, to: :confirmed
      transitions from: :confirmed, to: :in_production
      transitions from: :in_production, to: :ready
      transitions from: :ready, to: :shipped
      transitions from: :shipped, to: :delivery
    end
    event :back do
      transitions from: :confirmed, to: :unanswered
      transitions from: :in_production, to: :confirmed
      transitions from: :ready, to: :in_production
      transitions from: :shipped, to: :ready
      transitions from: :delivery, to: :shipped
    end
    event :refuse do
      transitions to: :refused
    end
    event :review do
      transitions to: :unanswered
    end
  end

  def regional_message
    messages.find_by(type: 'BidMessage', chat_id: region.chat_id)
  end
end

class DoctorBid < Bid
  after_create :send_to_admins

  def self.model_name
    Bid.model_name
  end

  def self.name
    "Докторская"
  end

  def send_auxiliary_message
    return unless region.chat_id
    case aasm_state
    when 'confirmed'
      msg = messages.create(chat_id: region.chat_id, type: 'BidMessage')
      msg.send_auxiliary_message('PlanMessage')
    when 'in_production'
      regional_message&.send_auxiliary_message('ProducedMessage')
    when 'shipped'
      No regional chatsend_auxiliary_message('DeliveredMessage')
    end
  rescue
    Telegram.bot.send_message(chat_id: 190444644, text: 'No regional chat')
  end

  def send_to_admins
    messages.create(chat_id: ENV['AdminChannel'], type: 'AdminBidMessage')
  end
end

class MakerBid < Bid

  def send_auxiliary_message
    case aasm_state
    when 'unanswered'
      regional_message.send_auxiliary_message('RequestMessage')
    end
  rescue
    Telegram.bot.send_message(chat_id: 190444644, text: 'No regional chat')
  end


  def self.model_name
    Bid.model_name
  end

  def self.name
    "Мейкерская"
  end

  after_create :generate_positions

  def generate_positions
    %w(PLA_кг PETG_кг ABS_кг SBS_кг ПЭТ_кв_м).each do |supply_type|
      positions.create(name: supply_type)
    end
  end
end