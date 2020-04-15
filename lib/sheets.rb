# frozen_string_literal: true

class Sheets
  def self.write(range, values)
    # https://github.com/gsuitedevs/ruby-samples/blob/master/sheets/snippets/lib/spreadsheet_snippets.rb
    # https://developers.google.com/sheets/api/guides/values
    # '1lGaktxyQsMK_xT-EZahpRP-6Rso76ouJxmsjARddxp0'
    spreadsheet_id = ENV['Spreadsheet_id']
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: range, values: values)
    result = service.update_spreadsheet_value(spreadsheet_id,
                                              range,
                                              value_range_object,
                                              value_input_option: 'USER_ENTERED')
  end

  def self.get(range = 'A1:Z10000')
    spreadsheet_id = ENV['Spreadsheet_id']
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: range)
    result = service.get_spreadsheet_values(spreadsheet_id,
                                            range)
    result.values
  end

  def self.service
    oob_uri = 'urn:ietf:wg:oauth:2.0:oob'
    application_name = 'Google Sheets API Ruby Quickstart'
    token_path = 'config/token.yaml'
    scope = Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    client_id = Google::Auth::ClientId.from_hash({"installed" =>
                                                      {"client_id" => "361116142880-c4aok8qti2vs8v7o60kr7er9d16vaste.apps.googleusercontent.com",
                                                       "project_id" => "quickstart-1564614340765",
                                                       "auth_uri" => "https://accounts.google.com/o/oauth2/auth",
                                                       "token_uri" => "https://oauth2.googleapis.com/token",
                                                       "auth_provider_x509_cert_url" => "https://www.googleapis.com/oauth2/v1/certs",
                                                       "client_secret" => ENV['Google_client_secret'],
                                                       "redirect_uris" => ["urn:ietf:wg:oauth:2.0:oob", "http://localhost"]}})
    token_store = Google::Auth::Stores::FileTokenStore.new file: token_path
    authorizer = Google::Auth::UserAuthorizer.new client_id, scope, token_store
    user_id = 'default'
    credentials = authorizer.get_credentials user_id
    if credentials.nil?
      url = authorizer.get_authorization_url base_url: oob_uri
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
          user_id: user_id, code: code, base_url: oob_uri
      )
    end
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = application_name
    service.authorization = credentials
    service
  end
end
