require 'sinatra/base'
require 'json'

# FakeZenDesk is a mocked version of the ZenDesk API endpoints
class FakeZenDesk < Sinatra::Base
	post '/api/v2/tickets' do
		content_type :json
		status 201
		{:ticket => {:id => 100001}}.to_json
	end
end
