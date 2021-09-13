require 'rubygems'
require 'base64'
require 'openssl'
require 'sinatra'
require 'active_support/security_utils'
require 'shopify_api'
require 'rails'

# The Shopify app's shared secret, viewable from the Partner dashboard
# webhook string
SHARED_SECRET = '86b895992ac3377d945d29a232e84746ab59e58430b5ecca9ac3db34e73148ab'
API_KEY = 'af5dbb553f3e90d76eb99f253d285a69'
PASSWORD = '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'
SHOP_NAME = 'kain-kain-store'

# Shopify API gem setup
shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
ShopifyAPI::Base.site = shop_url
ShopifyAPI::Base.api_version = '2021-07'

helpers do
  # Compare the computed HMAC digest based on the shared secret and the request contents
  # to the reported HMAC in the headers
  def verify_webhook(data, hmac_header)
    calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', SHARED_SECRET, data))
    ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
  end
end

# Respond to HTTP POST requests sent to this web service
post '/webhook/product_update' do
  request.body.rewind
  data = request.body.read
  verified = verify_webhook(data, env["HTTP_X_SHOPIFY_HMAC_SHA256"])
  unless verified
    return [403, 'Authorization failed. Provided hmac was #{hmac_header}']
  end

  # Output 'true' or 'false'
  puts "Webhook verified: #{verified}"

  json_data = JSON.parse data

  # Find product and add 'Updated' tag
  product = ShopifyAPI::Product.find(json_data['id'].to_i)

  product.tags += ', Updated'
  product.save

  # Always let Shopify know that we have received the webhook
  return [200, 'Webhook successfully received']
end

get '/' do
  "Welcome to Shopify Webhook App! 🎉"
end