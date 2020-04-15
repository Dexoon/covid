# frozen_string_literal: true
class TelegramWebhooksController < Telegram::Bot::UpdatesController
  #include Telegram::Bot::UpdatesController::TypedUpdate
  include Telegram::Bot::UpdatesController::MessageContext
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  include Telegram::Bot::UpdatesController::Session
  before_action :set_globals, except: %i[channel_post edited_channel_post edited_message unsupported_payload_type]

  def start!(*)
    if chat['id'] == from['id']
      session.delete(:context)
      if session['region']
        respond_with :message, text: 'Что вы хотите прислать?', reply_markup: {
            keyboard: %i(report thanks region).map do |x|
              [{text: I18n.t('telegram_webhooks.reply_buttons')[x]}]
            end,
            one_time_keyboard: true
        }
      else
        region
      end

    else
      bot.send_message(chat_id: ENV['RawChannel'], text: "#{chat['id']}
      #{chat['title']}")
      respond_with :message, text: 'Чат в процессе добавления'
    end
  end

  def region(code = nil)
    if code.nil?
      respond_with :message, text: 'Введите код вашего региона'
      save_context :region
    else
      session['region'] = Region.find_by(code: code)
      respond_with :message, text: "Ваш регион: #{session['region']}"
      start!
    end
  end

  def amount(number)
    report = session['report']
    if report.nil?
      respond_with :message, text: "Что-то пошло не так, попробуйте заново"
      start!
      return
    end
    report.product += [number]
    report.save!
    respond_with :message, text: "Прикрепите фото (видео) готовой продукции"
  end

  def product(*name)
    name = name.join(' ')
    report = session['report']
    if report.nil?
      respond_with :message, text: "Что-то пошло не так, попробуйте заново"
      start!
      return
    end
    report.product += [name]
    report.save!
    respond_with :message, {text: "Введите количество продукта",
                            reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
    save_context :amount

  end

  def order(number)
    report = Report.find_or_create_by(region: session['region'], order: number)
    if report.save
      session['report'] = report
      respond_with :message, text: "Выберите доставляемый продукт", reply_markup: {
          keyboard: ['Лупа', 'Пупа', 'Залупа', 'За пупа'].map do |text|
            [{text: text}]
          end,
          one_time_keyboard: true
      }
      respond_with :message, {text: "В случае ошибки в номере заказа, нажмите 'Ошибка/отмена'",
                              reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
      save_context :product
    else
      respond_with :message, text: "Что-то пошло не так, попробуйте заново"
      start!
    end

  end

  def report
    respond_with :message, {text: I18n.t('telegram_webhooks.report.text'),
                            reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
    save_context :order
  end

  def message(message)
    # if message.reply_to_message && message['chat_id'] == ENV['Photo_chat'] && message.reply_to_message['photo']
    # return bot.send_photo(chat_id: ENV['Photo_channel'],
    #                       photo: message.reply_to_message['photo'].last['file_id'],
    #                      caption: message['text'])
    # end
    # send_error(message_context_session.to_h.to_s)
    return photo(message) unless message['photo'].nil? && message['document'].nil?
    buttons = I18n.t('telegram_webhooks.reply_buttons').invert
    return self.send(buttons[message['text']]) unless buttons[message['text']].nil?
    @message.reply(message['text']) if @message

  rescue StandardError => msg
    send_error(msg)
  end

  def thanks
    respond_with :message, {text: I18n.t('telegram_webhooks.thanks.text'),
                            reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
    save_context :doctor_photo
  end

  def doctor_photo
    reply_with :message, {text: "Врач согласился на использование видео в открытых источниках?",
                          reply_markup: {inline_keyboard:
                                             I18n.t('telegram_webhooks.doctor_photo.buttons').map { |key, text|
                                               [{text: text, callback_data: "doctor:#{key}"}]
                                             }}}
  end

  def doctor_callback_query(data)
    forward_to_channel(payload['message']['reply_to_message'], 'Doctor_channel', I18n.t("telegram_webhooks.doctor_photo.buttons.#{data}"))
    answer_callback_query('')
  end

  def help!(*)
  rescue StandardError => msg
    send_error(msg)
  end

  def forward_to_channel(message, channel = 'Photo_channel', caption = '')
    report = session['report']
    if report.nil?
      forwarded = bot.forward_message(chat_id: 'Lost_channel',
                                      from_chat_id: message['chat']['id'],
                                      message_id: message['message_id'])
      respond_with :message, text: "Что-то пошло не так, попробуйте заново"
      start!
      return
    end
    if channel == 'Doctor_channel'
      save_context :doctor_photo
      respond_with :message, text: 'Можете прислать ещё фото/видео, с благодарностью врача, необязательно нажимать на кнопки внизу'
    else
      respond_with :message, text: 'Можете прислать ещё фото/видео, с отчётом, необязательно нажимать на кнопки внизу'
    end
    start!
    bot.send_message(chat_id: ENV[channel], text: "#{report}\n#{caption}\n#{@user}", parse_mode: 'HTML')
    forwarded = bot.forward_message(chat_id: ENV[channel],
                                    from_chat_id: message['chat']['id'],
                                    message_id: message['message_id'])

    report.photo += ["t.me/c/#{ENV['Photo_channel'][4..-1]}/#{forwarded['result']['message_id']}"]
    report.save
  end

  def photo(message)
    forward_to_channel(message)
  end

  def document(message)
    forward_to_channel(message)
  end

  def supply
    region = Region.where(chat_id: chat['id']).order(code: :desc)[0]
    return respond_with :message, text: 'Кажется, этот чат не добавлен' if region.nil?

    respond_with :message, {text: 'Выберите, какого материала вам не хватает',
                            reply_markup: {
                                inline_keyboard:
                                    Kernel.const_get("MakerSupply").descendants.map { |d| [{text: d.name, callback_data: "supply:#{d}"}] }
                            }}
  end

  def supply_callback_query(data)
    region = Region.where(chat_id: chat['id']).order(code: :desc)[0]
    bid = Bid.create(type: "MakerBid", region: region)
    bid.positions.create(type: data)
    answer_callback_query('')
  end

  def cancel_callback_query(data)
    session.delete(:context)
    session.delete(:report)
    answer_callback_query('')
    start!
  end

  def approve_callback_query(data)
    @message.archmessage.confirm!
    answer_callback_query(t('.confirm'), show_alert: true)
  end

  def next_callback_query(data)
    @message.archmessage.next!
    answer_callback_query(t('.next'), show_alert: true)
  end


  def back_callback_query(data)
    @message.archmessage.back!
    answer_callback_query(t('.back'), show_alert: true)
  end


  def refuse_callback_query(data)
    @message.archmessage.refuse!
    answer_callback_query(t('.refuse'), show_alert: true)
  end

  def review_callback_query(data)
    @message.archmessage.review!
    answer_callback_query(t('.review'), show_alert: true)
  end

  def callback_query(data)
    answer_callback_query(t('.error'), show_alert: true)
  end


  private

  def send_error(msg)
    if msg.message.include? 'specified new message content and reply markup are exactly the same as a current content and reply markup of the message'
      answer_callback_query('')
      return
    end
    first_message = bot.send_message(chat_id: ENV['Errors_channel'],
                                     text: "#{bot.username}: #{@user}\n#{msg}")
    update.to_h.to_s.scan(/.{1,4000}/m).each do |batch|
      bot.send_message(chat_id: ENV['Errors_channel'], reply_to_message_id: first_message['message_id'], text: batch)
    end
    return if msg.class == ''.class
    text = msg.backtrace.join("\n").gsub(/#{Rails.root.to_s}/, 'ROOT').gsub(/^.*gems/, 'GEMS')
    text.scan(/.{1,4000}/m).each do |batch|
      bot.send_message(chat_id: ENV['Errors_channel'], reply_to_message_id: first_message['message_id'], text: batch)
    end
  end

  # In this case session will persist for user only in specific chat.
  # Same user in other chat will have different session.
  def set_globals
    return unless from
    if payload_type == 'message' && payload['reply_to_message']
      @message = Message.find_by(chat_id: chat['id'], message_id: payload['reply_to_message']['message_id'])
    elsif payload_type == 'callback_query'
      @message = Message.find_by(chat_id: chat['id'], message_id: payload['message']['message_id'])
    end
    @user = User.find_by(tg_id: from['id'])
    if @user.nil?
      @user = User.find_by(tg_id: from['id'])
      username = from['username']
      @user = User.create(tg_id: from['id'], name: "#{from['first_name']} #{from['last_name']}", username: username) if @user.nil?
      @user.update(username: username) unless username == @user.username
    end
  rescue StandardError => msg
    send_error(msg)
  end

  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end

  protected

end
