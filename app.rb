require 'rubygems'
require 'base64'
require 'openssl'
require 'sinatra'
require 'active_support/security_utils'
require 'shopify_api'
require 'rails'
require 'sendgrid-ruby'
include SendGrid

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
# PRODUCT UPDATE
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
  product_title = json_data['title']
  puts "Product: #{product_title}"
  product.tags += ', Updated'
  product.save

  # Always let Shopify know that we have received the webhook
  return [200, 'Webhook successfully received']
end

# ORDER PAYMENT
# A webhook will be sent every time an order has been paid
# Send email / SMS when the order has been marked as paid
post '/webhook/order_payment' do
  request.body.rewind
  data = request.body.read
  verified = verify_webhook(data, env["HTTP_X_SHOPIFY_HMAC_SHA256"])
  unless verified
    return [403, 'Authorization failed. Provided hmac was #{hmac_header}']
  end

  # Output 'true' or 'false'
  puts "Webhook verified: #{verified}"

  json_data = JSON.parse data

  # Find order and check financial status
  order_number = json_data['order_number']
  financial_status = json_data['financial_status']
  puts "Order: #{order_number}"
  puts "Payment status: #{financial_status}"

  # Check if customer registered using email or phone number for order updates
  contact_email = json_data['contact_email']
  phone = json_data['phone']
  if contact_email
    # puts "Customer email: #{email}"

    # Send email using Twilio Sendgrid
    from = Email.new(email: 'fadhlina@synomus.io')
    to = Email.new(email: contact_email)
    subject = 'Kain Kain Store'
    content = Content.new(type: 'text/plain', value: 'Hi. Your payment for this order has been received. Thank you for shopping with us!')
    mail = Mail.new(from, subject, to, content)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._('send').post(request_body: mail.to_json)
    puts response.status_code
    puts response.body
    puts response.headers
    
  else phone
    puts "Customer phone number: #{phone}"
    # send sms
  end

  # Always let Shopify know that we have received the webhook
  return [200, 'Webhook successfully received']

end

# Respond to HTTP GET request
get '/' do
  "Welcome to Shopify Webhook App! 🎉"
end

