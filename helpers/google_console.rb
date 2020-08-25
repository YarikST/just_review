require 'google/apis/androidpublisher_v2'
require 'signet/oauth_2/client'
require 'rest-client'
module GoogleConsole

  #systems

  def auth
    settings = Setting.first

    auth = Signet::OAuth2::Client.new(
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        scope: "https://www.googleapis.com/auth/androidpublisher",
        client_id: settings.android_client_id,
        client_secret: settings.android_client_secret,
        refresh_token: settings.android_token_refresh
    )

    auth
  end

  def service
    settings = Setting.first
    service = Google::Apis::AndroidpublisherV2::AndroidPublisherService.new
    service.key = settings.android_key
    service.authorization = auth
    service
  rescue Exception => e

  end

  #product

  def in_app_product(dictionary)
    settings = Setting.first

    default_price = Class::Google::Apis::AndroidpublisherV2::Price.new
    default_price.currency= "UAH"
    default_price.price_micros=(convert_price(dictionary)*1000000).round(2).to_i

    listing =Google::Apis::AndroidpublisherV2::InAppProductListing.new
    listing.description= dictionary.description
    listing.title= dictionary.name

    listings={
        ENV['CONSOLE_LANG'] => listing,
        dictionary.native_language => listing
    }


    product = Google::Apis::AndroidpublisherV2::InAppProduct.new default_language: ENV['CONSOLE_LANG'],
                                                                 default_price: default_price,
                                                                 package_name: settings.android_package_name,
                                                                 listings: listings,
                                                                 purchase_type: "managedUser",
                                                                 sku: dictionary.uuid,
                                                                 status: "active"
    product
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  #subscription

  def in_app_subscription(subscriptions_setting)
    settings = Setting.first
    default_price = Class::Google::Apis::AndroidpublisherV2::Price.new
    default_price.currency="UAH"
    default_price.price_micros=(convert_price(subscriptions_setting)*1000000).round(2).to_i

    listing=nil

    I18n.with_locale("en-GB") do
      listing =Google::Apis::AndroidpublisherV2::InAppProductListing.new
      listing.description= I18n.t("subscriptions.popup.text.#{subscriptions_setting.subscription_period}.name")
      listing.title= I18n.t("subscriptions_settings.#{subscriptions_setting.subscription_period}.name")
    end

    listings={
        ENV['CONSOLE_LANG'] => listing
    }


    product = Google::Apis::AndroidpublisherV2::InAppProduct.new default_language: ENV['CONSOLE_LANG'],
                                                                 default_price: default_price,
                                                                 package_name: settings.android_package_name,
                                                                 listings: listings,
                                                                 purchase_type: "subscription",
                                                                 sku: subscriptions_setting.uuid,
                                                                 status: "active",
                                                                 subscription_period: subscriptions_setting.subscription_period
    if subscriptions_setting.trial_period.present?
      product.trial_period = "P#{subscriptions_setting.trial_period}D"
    end

    product
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e
    p e
  end

  #api

  def insert_in_app_product(product)
    settings = Setting.first
    service.insert_in_app_product(settings.android_package_name, product, auto_convert_missing_prices: true)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  def update_in_app_product(product)
    settings = Setting.first
    service.update_in_app_product(settings.android_package_name, product.sku, product, auto_convert_missing_prices: true)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  def delete_in_app_product(product)
    settings = Setting.first
    service.delete_in_app_product(settings.android_package_name, product.sku)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  def cancel_subscription(token, sku)
    settings = Setting.first
    service.cancel_purchase_subscription(settings.android_package_name, sku, token)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  def list_in_app_products
    settings = Setting.first
    service.list_in_app_products(settings.android_package_name)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  #validate

  def purchase_product(token, sku)
    settings = Setting.first
    service.get_purchase_product(settings.android_package_name, sku, token)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  def purchase_subscription(token, sku)
    settings = Setting.first
    service.get_purchase_subscription(settings.android_package_name, sku, token)
  rescue Google::Apis::ClientError => e
    raise
  rescue Exception => e

  end

  def android_receipt_product(dictionary_uuid, token)
    settings = Setting.first
    uri = "https://www.googleapis.com/androidpublisher/v2/applications/#{settings.android_package_name}/purchases/products/#{dictionary_uuid}/tokens/#{token}?access_token=#{service.authorization.fetch_access_token['access_token']}"

    response = RestClient::Request.execute method: :get,
                                           url: uri,
                                           headers: {'Content-Type': 'application/json'}
    JSON.parse response.body
  end

  def android_receipt_subscription(subscription_uuid, token)
    settings = Setting.first
    uri = "https://www.googleapis.com/androidpublisher/v2/applications/#{settings.android_package_name}/purchases/subscriptions/#{subscription_uuid}/tokens/#{token}?access_token=#{service.authorization.fetch_access_token['access_token']}"

    response = RestClient::Request.execute method: :get,
                                           url: uri,
                                           headers: {'Content-Type': 'application/json'}
    JSON.parse response.body
  end

  # activated or deactivated

  def active(product)
    product.status = "active"
    update_in_app_product product
  end

  def inactive(product)
    product.status = "inactive"
    update_in_app_product product
  end

  def convert_price(obj)
    RestClient::Request.execute(
        method: :get,
        url: "https://openexchangerates.org/api/latest.json",
        payload: {
        },
        headers: {'Content-Type': 'application/json', Authorization: 'Token d8743e82042c4856ba6268fc14e44856'}
    )do |response, request, result|
      response = JSON.parse(response)
      (obj.price * response['rates']['UAH']).round(2)
    end
  end

end