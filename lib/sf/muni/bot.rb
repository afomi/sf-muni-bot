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
        @api = Sf::Muni::Api.new

        # hard-coded
        # because Agencies should not change
        # often enough to warrant an API call
        @valid_agencies = [
          "AC Transit",
          "BART",
          "Caltrain",
          "Dumbarton Express",
          "LAVTA",
          "Marin Transit",
          "SamTrans",
          "SF-MUNI",
          "Vine (Napa County)",
          "VTA",
          "WESTCAT"
        ]

        client.on :hello do
          puts "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
        end

        # as a bot, what have I done?
        @memory = {
          ive_given_a_helpful_nudge: false,

          valid_agencies: @valid_agencies,
          selected_agency: "",

          valid_routes: [],      # the full object
          valid_route_names: [], # just the :name strings
          selected_route: "",
          selected_route_id: "", # because we have to pass the code, not the string

          valid_stops: [],
          valid_stop_names: [],
          selected_stop: "",

          selected_direction: "",

          departure_times: []
        }

        client.on :message do |data|
          puts data

          # actions_string = api.urls.keys.collect { |key| "\`#{key}\` \n"}.join(", ")

          # Handle user input here.
          message = data['text']

          # Give an initial nudge.
          # To get the conversation going.
          if @memory[:ive_given_a_helpful_nudge] == false
            helpful_nudge = "Hi, I'm not sure I understood that. But, I can do the following:\n #{agencies}"

            helpful_nudge = "Hi, I'm not sure I understood that. But here's what I'm about: I provide Transportation info for 511 Agencies in the San Francisco Bay Area.\n\n Which Agency do you want? Select an Agency below. \n\n #{@api.get_agencies.collect { |agency| agency[:name] }.join("\n")}"

            client.message channel: data['channel'], text: helpful_nudge
            @memory[:ive_given_a_helpful_nudge] = true
          end

          if @valid_agencies.include?(message) && @memory[:selected_agency] != message
            # RESET
            @memory = {
              valid_routes: [],      # the full object
              valid_route_names: [], # just the :name strings
              selected_route: "",
              selected_route_id: "", # because we have to pass the code, not the string

              valid_stops: [],
              valid_stop_names: [],
              selected_stop: "",

              selected_direction: "",

              departure_times: []
            }

            @memory[:selected_agency] = message
          elsif @valid_agencies.include?(message)
            # Respond when selecting an Agency.
            @memory[:selected_agency] = message

            client.message channel: data['channel'], text: "You have selected *#{message}*"
          end

          if "inbound" == message.capitalize.downcase
            @memory[:selected_direction] = "Inbound"
          elsif "outbound" == message.downcase
            @memory[:selected_direction] = "Outbound"
          end

          # When selecting an Agency...
          if !@memory[:selected_agency].empty? &&
            @memory[:valid_routes].empty?

            @memory[:valid_routes] = @api.get_routes_for_agency(@memory[:selected_agency])
            @memory[:valid_route_names] = @memory[:valid_routes].collect { |route| route[:name] }

            client.message channel: data['channel'], text: "Here are the Routes for #{@memory[:selected_agency]}: \n\n #{@memory[:valid_route_names].join("\n")} \n\n Which Route would you like?"
          end

          # When selecting a Route...
          if @memory[:valid_route_names].include?(message) &&
            @memory[:selected_route].empty?

            @memory[:selected_route] = message
            @memory[:selected_route_id] = @memory[:valid_routes].select { |route| route[:name] == message }.first[:code]

            begin
              @memory[:valid_stops] = @api.get_stops_for_route(agency: @memory[:selected_agency], route_id: @memory[:selected_route_id], direction_code: @memory[:selected_direction])
            rescue ArgumentError => e
              @memory[:selected_route] = ""

              client.message channel: data['channel'], text: "This Route requires a Direction. Are you going 'Inbound', or 'Outbound'?"
            end

            @memory[:valid_stop_names] = @memory[:valid_stops].collect { |stop| stop[:name]}

            client.message channel: data['channel'], text: "Here are the Stops on the *#{@memory[:selected_route]}* Route: \n\n #{@memory[:valid_stop_names].join("\n")} \n\n Which Stop would you like?"
          end

          # When selecting a Stop...
          if @memory[:valid_stop_names].include?(message) && !@memory[:selected_route].empty?

            @memory[:selected_stop] = message

            @memory[:departure_times] =            @api.get_next_departures_by_stop_name(agency_name: @memory[:selected_agency], stop_name: @memory[:selected_stop])

            client.message channel: data['channel'], text: "Here are the Next Departure Times for the *#{@memory[:selected_stop]}* Station on the *#{@memory[:selected_route]}* Route: \n\n #{@memory[:departure_times].collect { |time| time[:leaving_in] }.join("\n")} \n\n That's the extent of my capabilities for now. Want to return to the start? Say 'hi'. - SF Muni Bot"
          end

          case message
          when "help" then
            client.message channel: data['channel'], text: "Hi, I can do the following:\n #{agencies}"
          when "get_agencies" then
            client.message channel: data['channel'], text: "Getting Agencies..."
            client.message channel: data['channel'], text: @api.get_agencies.collect { |agency| agency[:name] }.join("\n")
          when "get_routes_for_agencies" then
            client.message channel: data['channel'], text: @api.get_routes_for_agencies
          when "get_routes_for_agency" then
            client.message channel: data['channel'], text: "get_routes_for_agency"
          when "get_stops_for_route" then
            client.message channel: data['channel'], text: "get_stops_for_route"
          when "get_stops_for_routes" then
            client.message channel: data['channel'], text: "get_stops_for_routes"
          when "get_next_departures_by_stop_name" then
            client.message channel: data['channel'], text: "get_next_departures_by_stop_name"
          when "get_next_departures_by_stop_code" then
            client.message channel: data['channel'], text: "get_next_departures_by_stop_code"
          end
        end

        client.start!
      end

      def agencies
        @api.urls.keys.collect { |key| "\`#{key}\`"}.join("\n")
      end
    end
  end
end

Sf::Muni::Bot.new
