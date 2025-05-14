
require 'bundler/setup'
require 'dotenv/load'
require 'line/bot'
require 'pp'

client = Line::Bot::V2::MessagingApi::ApiClient.new(
  channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
)

message = Line::Bot::V2::MessagingApi::TextMessage.new(text: "こんにちは、Bokriumです📚")

request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
  to: ENV.fetch("MY_LINE_USER_ID"),
  messages: [message]
)

response = client.push_message(push_message_request: request)

if response.class.name.include?("ErrorResponse")
  puts "Message: #{response.message}"
  puts "Details: #{response.details.inspect}"
  puts "Status: #{response.instance_variable_get(:@data)&.[](:status)}"
else
  puts "Success!"
end