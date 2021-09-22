# Download the twilio-ruby library from twilio.com/docs/libraries/ruby
require 'twilio-ruby'

account_sid = 'AC3d1d141e02281cde6f86b7e9371ec70d' 
auth_token = 'a77ddec81338da65616b9b0c2c6becad'
client = Twilio::REST::Client.new(account_sid, auth_token)

from = '+12018176607' # Your Twilio number
to = '+6738640624' # Your mobile phone number

client.messages.create(
from: from,
to: to,
body: "Hey friend!"
)
