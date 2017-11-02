ENV['RACK_ENV'] = 'test'

require 'rack/test'

RSpec.describe "Content", :type => :feature do

    include Rack::Test::Methods

    def app()
        Rack::Builder.parse_file("config.ru").first
    end

    def middleware_modules()
        app.middleware.map {|middleware_config| middleware_config[0]}
    end

    it "should use Rack::Protection::PathTraversal" do
        expect(middleware_modules).to include(Rack::Protection::PathTraversal)
    end

end
