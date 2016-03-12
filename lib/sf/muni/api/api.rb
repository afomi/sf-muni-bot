require 'json'
require 'nokogiri'
require 'open-uri'

module Sf
  module Muni
    class Agency
    end

    class Api
      attr_reader :token, :urls,
        :agencies, :routes

      def initialize
        @token = token
        @urls = urls
        @agencies = []
        @routes = []
      end

      def token
        ENV.fetch("SFMUNI_511_TOKEN")
      end

      # Call the 511 API.
      def get(path, options = {})
        url = @urls[path]
        url = "#{url}?token=#{token}"

        if !options.empty?
          query_params = ""

          options.each_pair { |key, value|
            query_params += "&#{key}=#{value}"
          }
          url = url + query_params
        end

        puts "URL =========================>"
        puts url
        open(url).read
      end

      # Parse the XML response with Nokogiri.
      def parse(string)
        Nokogiri::XML(string)
      end

      # Note: URLs are called, by convention from `#get` based on the method name.
      # See the `#get_agencies` method as one example.
      def urls
        {
          get_agencies: "http://services.my511.org/Transit2.0/GetAgencies.aspx",
          get_routes_for_agencies: "http://services.my511.org/Transit2.0/GetRoutesForAgencies.aspx",
          get_routes_for_agency: "http://services.my511.org/Transit2.0/GetRoutesForAgency.aspx",
          get_stops_for_route: "http://services.my511.org/Transit2.0/GetStopsForRoute.aspx",
          get_stops_for_routes: "http://services.my511.org/Transit2.0/GetStopsForRoutes.aspx",
          get_next_departures_by_stop_name: "http://services.my511.org/Transit2.0/GetNextDeparturesByStopName.aspx",
          get_next_departures_by_stop_code: "http://services.my511.org/Transit2.0/GetNextDeparturesByStopCode.aspx"
        }
      end

      def get_agencies
        parse_agencies parse(get(__method__))
      end

      def parse_agencies(nodes)
        return if !@agencies.empty?

        nodes.css("Agency").each do |agency|
          hash = {
            name: agency.attr("Name"),
            has_direction: agency.attr("HasDirection"),
            mode: agency.attr("Mode")
          }
          @agencies << hash
        end

        @agencies
      end

      def get_routes_for_agencies(options = {})
        @routes = []

        nodes = parse(get(__method__, options))
        nodes.css("Route").each do |route|
          hash = {
            name: route.attr("Name"),
            code: route.attr("Code")
          }
          @routes << hash
        end

        @routes
      end

      def get_routes_for_agency(agency = "")
        @routes = []
        nodes = parse(get(__method__, { "agencyName" => agency }))

        nodes.css("Route").each do |route|
          hash = {
            name: route.attr("Name"),
            code: route.attr("Code")
          }
          @routes << hash
        end

        @routes
      end

      def get_stops_for_route(agency: "", route_id: "", direction_code: "")
        @stops = []
        nodes = parse(get(__method__, { "routeIDF" => "#{agency}~#{route_id}#{if !direction_code.empty?; '~' + direction_code; end}" }))

        if !nodes.css("transitServiceError").empty?
          raise ArgumentError, "transitServiceError"
        end

        nodes.css("Stop").each do |route|
          hash = {
            name: route.attr("name"),
            stop_code: route.attr("StopCode")
          }
          @stops << hash
        end

        @stops
      end

      def get_stops_for_routes
        parse(get(__method__))
      end

      def get_next_departures_by_stop_name(agency_name: "", stop_name: "")
        @departures = []

        nodes = parse(get(__method__, { "agencyName" => agency_name, "stopName" => stop_name }))

        nodes.css("Route").each do |time|
          hash = {
            leaving_in: time.text
          }
          @departures << hash
        end

        @departures
      end

      def get_next_departures_by_stop_code
        parse(get(__method__))
      end
    end
  end
end
