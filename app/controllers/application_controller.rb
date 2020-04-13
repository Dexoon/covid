class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: :webhook

  def webhook
    begin
      data = JSON.parse(request.body.read)['response']['payload']
      Telegram.bot.send_message(chat_id: 190444644, text: data.to_s)
      #method = "handle_" + event['type'].tr('.', '_')
      #self.send method, event
      organization = data['Название вашей организации']
      name = data['Как вас зовут (ФИО)']
      phone = data['Мобильный телефон для связи с вами (+7XXXXXXXX)']
      region = data['Область']
      code = region[0..1].to_i
      code = 77 if code == 50
      code = 78 if code == 47
      town = data['Город']
      hospital = data['Номер и адрес больницы']
      doctor = data['Врач больницы (контактное лицо)']
      shiled = data['Защитные щитки (шт.)'].to_i
      hairpin = data['Заколки для марлевых масок (шт.)'].to_i
      box = data['Защитные боксы (шт.), в том числе боксы для бронхоскопии'].to_i
      maskadapter = data['Переходники для снорклинг-масок (шт.)'].to_i
      contact_info = "Организация: #{organization}
Имя: #{name}
Телефон: #{phone}
Город: #{town}
Номер и адрес больницы: #{hospital}
Врач: #{doctor}\n"
      region = Region.find_by(code: code)
      bid = Bid.create(region: region, contact_info: contact_info, type: "DoctorBid")
      bid.positions.create(type: 'Shield', request: shiled) unless shiled == 0
      bid.positions.create(type: 'Hairpin', request: hairpin) unless hairpin == 0
      bid.positions.create(type: 'Box', request: box) unless box == 0
      bid.positions.create(type: 'MaskAdapter', request: maskadapter) unless maskadapter == 0
    rescue JSON::ParserError => e
      render json: {:status => 400, :error => "Invalid payload"} and return
    rescue NoMethodError => e
      # missing event handler
    end
    render json: {:status => 200}
  end
end
