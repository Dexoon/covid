# frozen_string_literal: true
class TelegramWebhooksController < Telegram::Bot::UpdatesController
  #include Telegram::Bot::UpdatesController::TypedUpdate #Почему-то TypedUpdate у меня не работает, поэтому выкдючил


  include Telegram::Bot::UpdatesController::MessageContext
  #Позволяет формировать контекст у сообщений.
  # Реализовано это через сохранение в session[:context] названия метода который будет вызван,
  # если придёт новое сообщение. В качестве аргументов этому методу подаётся набор сов в тексте сообщения


  include Telegram::Bot::UpdatesController::CallbackQueryContext

  include Telegram::Bot::UpdatesController::Session

  before_action :set_globals, except: %i[channel_post edited_channel_post edited_message unsupported_payload_type]

  def clean_start
    #Если что-то пошло не так, начать новую сессию
    session.delete(:context)
    session.delete(:report)
    start!
  end

  def start!(*)
    if chat['id'] == from['id'] # Если это ЛС
      if session['region']
        #Если известно из какого региона 
        respond_with :message, text: @fingerpint + 'Что вы хотите прислать?', reply_markup: {
            keyboard: %i(report thanks region).map do |x|
              [{text: I18n.t('telegram_webhooks.reply_buttons')[x]}]
            end,
            one_time_keyboard: true
        }
      else
        region
      end
    else
      # Посылает мне в канал id и название чата, в который добавили бота
      bot.send_message(chat_id: ENV['RawChannel'], text: "#{chat['id']}
      #{chat['title']}")
      respond_with :message, text: 'Чат в процессе добавления'
    end
  end

  def region(code = nil, *args)
    if code.nil?
      respond_with :message, text: 'Введите код вашего региона'
      save_context :region
      # Ждём ввода номера региона
    else
      session['region'] = Region.find_by(code: code)
      respond_with :message, text: "Ваш регион: #{session['region']}"
      start!
    end
  end

  def amount(number, *args)
    # В отчёт вводится сколько именно продукта доставили
    report = session['report']
    return something_went_wrong if report.nil?
    #Если отчёта нет в сессии, начинаем заново

    report.product += [number]
    # Немного кривая архитектура. report.product это массив строк, котрый выглядит так:
    # [Название_продукта_1, количество_продукта_1, Название_продукта_2, количество_продукта_2,...]
    report.save!
    respond_with :message, text: @fingerpint + "Прикрепите фото (видео) готовой продукции"
    #  Все картинки/видео по умолчанию прикрепляются к текущему (укзазанному в сессии) заказу,
    # поэтому ничего дополнительно делать не надо
  end

  def product(*name)
    # В отчёт вводится название продукта

    report = session['report']
    return something_went_wrong if report.nil?
    #Если отчёта нет в сессии, начинаем заново

    name = name.join(' ')
    # В случае, если название продукта состоит из нескольки слов,
    # то каждое слово - элекент массива аргументов, поэтому нужно объединять

    report.product += [name]
    report.save!
    respond_with :message, {text: @fingerpint + "Введите количество продукта",
                            reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
    save_context :amount
    #  Ждём вводаколичества
  end

  def order(number, *args)
    report = Report.find_or_create_by(region: session['region'], order: number)
    #    Создаём или находим отчёт по номеру заказа и региону
    if report
      session['report'] = report
      respond_with :message, text: @fingerpint + "Выберите доставляемый продукт", reply_markup: {
          keyboard: ['Щитки', 'Заколки', 'Боксы', 'Переходники'].map do |text|
            [{text: text}]
          end,
          one_time_keyboard: true
      }
      respond_with :message, {text: @fingerpint + "В случае ошибки в номере заказа, нажмите 'Ошибка/отмена'",
                              reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
      save_context :product
      #  Ждём ввода названия продукта

    else
      return something_went_wrong
    end

  end

  def report(*args)
    respond_with :message, {text: @fingerpint + I18n.t('telegram_webhooks.report.text'),
                            reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
    save_context :order
    # Ждём ввода номера заказа
  end

  def message(message) # Обработка водящего сообщения без контекста

    return photo(message) unless message['photo'].nil? && message['document'].nil?
    # Если в сообщении есть фото/видео (видео это документ), то переодим к его обработке
    # Эта строчка уже прописана в контроллере, но я её дублирую,
    # она у меня не всегда срабатывает почему-то

    buttons = I18n.t('telegram_webhooks.reply_buttons').invert #Список прописанных кнопок
    return self.send(buttons[message['text']]) unless buttons[message['text']].nil?
    # Если полученный текст, это название одной из кнопок, то перейти к
    # соответствующему методу

    @message.reply(message['text']) if @message
      #  Это из другой части бота

  rescue StandardError => msg
    send_error(msg)
  end

  def thanks(*args)
    respond_with :message, {text: @fingerpint + I18n.t('telegram_webhooks.thanks.text'),
                            reply_markup: {inline_keyboard: [[{text: 'Ошибка/отмена', callback_data: 'cancel:'}]]}}
    save_context :doctor_photo
    #Ждём фотографий/видео
  end

  def doctor_photo(*args)
    reply_with :message, {text: @fingerpint + "Врач согласился на использование видео в открытых источниках?",
                          reply_markup: {inline_keyboard:
                                             I18n.t('telegram_webhooks.doctor_photo.buttons').map { |key, text|
                                               [{text: text, callback_data: "doctor:#{key}"}]
                                             }}}
    save_context :doctor_photo unless payload['photo'].nil? && payload['document'].nil?
    #По умолчанию ждём ещё фотографий/видео
  end

  def doctor_callback_query(data)
    forward_to_channel(payload['message']['reply_to_message'], 'Doctor_channel', I18n.t("telegram_webhooks.doctor_photo.buttons.#{data}"))
    answer_callback_query('')
  end

  def forward_to_channel(message, channel = 'Photo_channel', caption = '', *args)
    report = session['report']
    if report.nil?
      forwarded = bot.forward_message(chat_id: 'Lost_channel',
                                      from_chat_id: message['chat']['id'],
                                      message_id: message['message_id'])
      # Форвардим сообщение в канал потерянных фотографий, на всякий случай
      return something_went_wrong
    end
    if channel == 'Doctor_channel'
      respond_with :message, text: @fingerpint + 'Можете прислать ещё фото/видео, с благодарностью врача, необязательно нажимать на кнопки внизу'
      save_context :doctor_photo
      #По умолчанию ждём ещё фотографий/видео
    else
      respond_with :message, text: @fingerpint + 'Можете прислать ещё фото/видео, с отчётом, необязательно нажимать на кнопки внизу'
    end
    start!

    bot.send_message(chat_id: ENV[channel], text: "#{report}\n#{caption}\n#{@user}", parse_mode: 'HTML')
    forwarded = bot.forward_message(chat_id: ENV[channel],
                                    from_chat_id: message['chat']['id'],
                                    message_id: message['message_id'])
    #Форвардим фото с комментарием в соответствующий канал

    report.photo += ["t.me/c/#{ENV['Photo_channel'][4..-1]}/#{forwarded['result']['message_id']}"]
    report.save
  end

  def something_went_wrong
    respond_with :message, text: @fingerpint + "Что-то пошло не так, попробуйте заново"
    start!
  end


  def cancel_callback_query(data)
    answer_callback_query('')
    clean_start
  end

  def photo(message)
    forward_to_channel(message)
  end

  def document(message)
    forward_to_channel(message)
  end

  #
  #
  #  ЗДЕСЬ НАЧИНАЕТСЯ ДРУГАЯ ЧАСТЬ БОТА, КОТОРАЯ В ИТОГЕ ОКАЗАЛАСЬ НЕВОСТРЕБОВАНА
  #
  #
  #



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


  def help!(*)
  rescue StandardError => msg
    send_error(msg)
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
    @fingerpint = ''
    @fingerpint += "#{session['report']&.order}," if session['report']
    @fingerpint += "#{session['region']&.code}\n" if session['region']
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
