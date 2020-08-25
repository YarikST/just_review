class SubscriptionWrapper

  class << self

    def get_apple_receipt ios_password, token
      response = send_apple_verification ios_password, token

      if response['status'].to_i == 0

      else
        message = ''
        case response['status']
        when 21000
          message = "The App Store could not read the JSON object you provided."
        when 21002
          message = "The data in the receipt-data property was malformed or missing."
        when 21003
          message = "The receipt could not be authenticated."
        when 21004
          message = "The shared secret you provided does not match the shared secret on file for your account. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions."
        when 21005
          message = "The receipt server is not currently available."
        when 21006
          message = "This receipt is valid but the subscription has expired. When this status code is returned to your server, the receipt data is also decoded and returned as part of the response. Only returned for iOS 6 style transaction receipts for auto-renewable subscriptions."
        when 21007
          message = "This receipt is from the test environment, but it was sent to the production environment for verification. Send it to the test environment instead."
        when 21008
          message = "This receipt is from the production environment, but it was sent to the test environment for verification. Send it to the production environment instead."
        else
          message = response['status']
        end
        response['message'] = message
      end

      response
    end


    private

    def send_apple_verification ios_password, token, type='live'
      uri_live  = 'https://buy.itunes.apple.com/verifyReceipt'
      uri_stage = 'https://sandbox.itunes.apple.com/verifyReceipt'

      response = RestClient::Request.execute method: :post,
                                             url: type == 'live' ? uri_live : uri_stage,
                                             payload: {'receipt-data': token, password: ios_password}.to_json,
                                             headers: {'Content-Type': 'application/json'}

      response = JSON.parse response.body

      if response['status'].to_i == 21007
        return send_apple_verification ios_password, token, 'stage'
      else
        return response
      end
    end

  end

end
