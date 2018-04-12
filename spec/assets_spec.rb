require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe "Static assets", :type => :feature do

	include Rack::Test::Methods

	def app()
		Rack::Builder.parse_file("config.ru").first
	end

	it "the logo image used by our PaaS emails should exist" do
		get "images/gov.uk_logotype_crown.png"
		expect(last_response.status).to eq(200)
	end

end
