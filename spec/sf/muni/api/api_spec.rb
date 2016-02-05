require 'spec_helper'

describe Sf::Muni::Api do
  before do
    @api = Sf::Muni::Api.new
  end

  describe "#token" do
    it "requires a token" do
      expect(@api.token).not_to be_empty
    end
  end

  it "has a token" do
    expect(@api.token).not_to be_empty
  end

  describe "#urls" do
    it 'has 7 URLs' do
      expect(@api.urls.class).to eq(Hash)
      expect(@api.urls).not_to be_empty
      expect(@api.urls.keys.size).to eq 7
    end
  end

  describe "each URL" do
    it "returns nodes" do
      @api.urls.each_pair do |path, url|
        puts "Testing #{path}"
        expect(@api.send(path).class).to eq(Nokogiri::XML::Document)
      end
    end
  end
end
