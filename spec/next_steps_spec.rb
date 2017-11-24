require 'rack/test'
require 'capybara/rspec'
require 'net/http'
Capybara.app = Rack::Builder.parse_file("config.ru").first

RSpec.describe 'Next steps', :type => :feature do

  include Rack::Test::Methods

  it 'should be able to load page successfully' do
    visit '/next-steps'
    expect(page).not_to have_selector('.account-created'), 'Did not expect to see "Your account has been activated" message'
    expect(page.status_code).to eq(200)
  end

  it 'should be able to load page successfully with account activated message' do
    visit '/next-steps?success'
    expect(page).to have_selector('.account-created'), 'Expected to see "Your account has been activated" message'
    expect(page.status_code).to eq(200)
  end

end
