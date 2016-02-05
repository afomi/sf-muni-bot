require 'slack-ruby-client'
require_relative "bot/version"
require_relative "api/api"

Slack.configure do |config|
  config.token = ENV.fetch("SLACK_API_TOKEN")
end

module Sf
  module Muni
    class Bot
      def initialize
        client = ::Slack::RealTime::Client.new

        client.on :hello do
          puts "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
        end

        client.on :message do |data|
          puts data

          # handle data["text"] here
        end

        client.start!
      end
    end
  end
end

Sf::Muni::Bot.new
