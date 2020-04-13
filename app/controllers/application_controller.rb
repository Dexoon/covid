class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: :webhook

  def webhook
    begin
      data = JSON.parse(request.body.read)['response']['payload']
      #method = "handle_" + event['type'].tr('.', '_')
      #self.send method, event
      phone = data['Номер телефона для звонков (в формате +79ХХ1234567)']
    rescue JSON::ParserError => e
      render json: {:status => 400, :error => "Invalid payload"} and return
    rescue NoMethodError => e
      # missing event handler
    end
    render json: {:status => 200}
  end
end
