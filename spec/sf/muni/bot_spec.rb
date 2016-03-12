require 'spec_helper'

describe Sf::Muni::Bot do
  it 'has a version number' do
    expect(Sf::Muni::Bot::VERSION).not_to be nil
  end

  context 'without a token' do
    before do
      ENV.delete("SLACK_API_TOKEN")
    end

    it "raises an error" do
      binding.pry
      expect(Sf::Muni::Bot.new).to raise_error Faraday::ClientError
    end
  end
end
