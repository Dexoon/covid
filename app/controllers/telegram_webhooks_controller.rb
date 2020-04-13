# frozen_string_literal: true
class TelegramWebhooksController < Telegram::Bot::UpdatesController
  #include Telegram::Bot::UpdatesController::TypedUpdate
  #include Telegram::Bot::UpdatesController::Session
  include Telegram::Bot::UpdatesController::CallbackQueryContext
  before_action :set_globals, except: %i[channel_post edited_channel_post edited_message unsupported_payload_type]
  #include Telegram::Bot::UpdatesController::MessageContext

  def start!(*)
    if chat['id'] == from['id']
      respond_with :message, text: 'hi'
    else
      bot.send_message(chat_id: ENV['RawChannel'], text: "#{chat['id']}
#{chat['title']}")
      respond_with :message, text: 'Чат в процессе добавления'
    end
  end


  def message(message)
    # if message.reply_to_message && message['chat_id'] == ENV['Photo_chat'] && message.reply_to_message['photo']
    # return bot.send_photo(chat_id: ENV['Photo_channel'],
    #                       photo: message.reply_to_message['photo'].last['file_id'],
    #                      caption: message['text'])
    # end
    # send_error(message_context_session.to_h.to_s)
    @message.reply(message['text']) if @message

  rescue StandardError => msg
    send_error(msg)
  end


  def help!(*)
  rescue StandardError => msg
    send_error(msg)
  end

  def photo(message)

  end

  def document(message)

  end

  def supply
    region=Region.find_by(chat_id:chat['id'])
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


  protected

end
