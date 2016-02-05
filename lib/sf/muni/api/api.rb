require 'json'
require 'nokogiri'
require 'open-uri'

module Sf
  module Muni
    class Api
      attr_reader :token, :urls

      def initialize
        @token = token
        @urls = urls
      end

      def token
        ENV.fetch("SFMUNI_511_TOKEN")
      end

      # Call the 511 API.
      def get(path)
        url = @urls[path]
        url = "#{url}?token=#{token}"
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
        parse(get(__method__))
      end

      def get_routes_for_agencies
        parse(get(__method__))
      end

      def get_routes_for_agency
        parse(get(__method__))
      end

      def get_stops_for_route
        parse(get(__method__))
      end

      def get_stops_for_routes
        parse(get(__method__))
      end

      def get_next_departures_by_stop_name
        parse(get(__method__))
      end

      def get_next_departures_by_stop_code
        parse(get(__method__))
      end
    end
  end
end
