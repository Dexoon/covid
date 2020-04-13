class Message < ApplicationRecord
  belongs_to :archmessage, polymorphic: true
  after_create :send_message

  def send_message
    return unless message_id.nil?

    msg = Telegram.bot.send_message({chat_id: chat_id, parse_mode: 'HTML'}.merge(view))
    update(message_id: msg['result']['message_id'])
  end

  def refresh
    Telegram.bot.edit_message_text({chat_id: chat_id,
                                    message_id: message_id, parse_mode: 'HTML'}.merge(view))
  rescue

  end
end

class BidMessage < Message

  def view
    {text: archmessage.to_text}
  end

  def send_auxiliary_message(type)
    position.messages.create(chat_id: chat_id, type: type)
  end
end

class AdminBidMessage < Message
  def view
    result = {text: archmessage.to_admin_text}
    case archmessage.aasm_state
    when 'unanswered'
      result.merge({reply_markup: {inline_keyboard: [[{text: 'Подтвердить', callback_data: 'approve:'}],
                                                     [{text: 'Отказать', callback_data: 'refuse:'}]]}})
    when 'refused'
      result.merge({reply_markup: {inline_keyboard: [[{text: 'Пересмотреть', callback_data: 'review:'}]]}})
    else
      result.merge({reply_markup: {inline_keyboard: [[{text: 'Дальше', callback_data: 'next:'}],
                                                     [{text: 'Назад', callback_data: 'back:'}]]}})
    end

  end
end

class AuxiliaryMessage < Message
  def refresh
  end

  def view
    {text: "#{archmessage.name} #{I18n.t("#{self.class.to_s}.text")}"}
  end
end

class RequestMessage < AuxiliaryMessage
  def reply(data)
    archmessage.update(request: data.to_f)
  end
end

class PlanMessage < AuxiliaryMessage
  def reply(data)
    archmessage.update(plan: data.to_f)
  end
end

class ProducedMessage < AuxiliaryMessage
  def reply(data)
    archmessage.update(produced: data.to_f)
  end
end

class DeliveredMessage < AuxiliaryMessage
  def reply(data)
    archmessage.update(delivered: data.to_f)
  end
end
