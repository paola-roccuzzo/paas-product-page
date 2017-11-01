ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe "Content", :type => :feature do

	include Rack::Test::Methods

	def app()
		Rack::Builder.parse_file("config.ru").first
	end

	seen = {}
	Dir['views/*.erb'].each do |template|

		next if /layout.erb/.match?(template)
		parent_path = template.gsub(/.erb$/, '').gsub(/^views/, '').gsub(/#.*/, '')

		it "should not have broken links in #{template}" do
			visit parent_path
			expect(page.status_code).to eq(200), "Failed to load page '#{parent_path}'"
			all('a').each do |link|
				url = link[:href]
				next if url.nil? or url.empty? or url.match?(/^#/) or seen[url]
				if url =~ /^https?:/
					res = Net::HTTP.get_response(URI(url))
					expect(res.code).to match(/^(200|301|302)$/), "there is a broken (#{res.code}) EXTERNAL link to '#{url}' on '#{parent_path}'"
				elsif url =~ /^\//
					visit url
					expect(page.status_code).to eq(200), "there is a broken (#{page.status_code}) link to '#{url}' on '#{parent_path}'"
				elsif url =~ /^mailto:/
					expect(url).to match(/^.+@.+$/)
				else
					fail "there is an invalid url '#{url}' on '#{parent_path}'"
				end
				seen[url] = true
			end
		end

		it "should redirect #{parent_path}.html -> #{parent_path}" do
			get "#{parent_path}.html"
			expect(last_response.status).to eq(301)
			location = last_response.headers['Location']
			expect(location).not_to be_nil
			expect(URI(location).path).to eq("#{parent_path}")
		end

		it "should provide the correct Content-Security-Policy" do
			get parent_path
			expect(last_response.status).to eq(200)
			expect(last_response.headers['Content-Security-Policy']).to eq("connect-src 'self'; default-src none; font-src 'self' data:; frame-src 'self'; img-src 'self' www.google-analytics.com; media-src 'self'; object-src 'self'; script-src 'self' www.google-analytics.com; style-src 'self' 'unsafe-inline'")
		end

	end

end
