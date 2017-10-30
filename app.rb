require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'sprockets'
require 'sprockets-helpers'

require './models/deskpro'
require './models/forms'
require 'erubis'

# App is the main Sinatra application
class App < Sinatra::Base

	set :sprockets, Sprockets::Environment.new
	set :title, 'GOV.UK Platform as a Service'
	set :erb, :escape_html => true

	use Rack::Protection::ContentSecurityPolicy,
		:default_src => 'none',
		:script_src => '\'self\' www.google-analytics.com',
		:style_src => '\'self\' \'unsafe-inline\'',
		:img_src => '\'self\' www.google-analytics.com',
		:connect_src => '\'self\'',
		:frame_src => '\'self\'',
		:font_src => '\'self\' data:',
		:object_src => '\'self\'',
		:media_src => '\'self\''

	configure do
		sprockets.append_path File.join(root, 'assets', 'stylesheets', 'govuk_frontend_toolkit')
		sprockets.append_path File.join(root, 'assets', 'stylesheets', 'govuk_elements')
		sprockets.append_path File.join(root, 'assets', 'stylesheets', 'govuk_template')
		sprockets.append_path File.join(root, 'assets', 'stylesheets')
		sprockets.append_path File.join(root, 'assets', 'fonts')
		sprockets.append_path File.join(root, 'assets', 'js')
		sprockets.append_path File.join(root, 'assets')
		Sprockets::Helpers.configure do |config|
			config.prefix      = '/'
			config.environment = sprockets
			config.public_path = public_folder
			config.debug       = true if development?
		end
		register Sinatra::Reloader if development?
	end

	helpers Sinatra::ContentFor
	helpers Sprockets::Helpers
	helpers Forms::Helpers

	get '/?' do
		erb :index
	end

	get '/contact-us' do
		@errors = {}
		@ticket = Deskpro::Ticket.new
		erb :'contact-us'
	end

	post '/contact-us' do
		@errors = {}
		@ticket = Deskpro::Ticket.new({
			subject: "#{Date.today.to_s} Support Request From Website",
			person_email: params[:person_email],
			person_name: params[:person_name],
			message: [
				"department: #{params[:department_name]}",
				"service: #{params[:service_name]}",
				params[:message] || '',
			].join("\n"),
			label: ['paas'],
		})
		@ticket.agent_team_id = ENV['DESKPRO_TEAM_ID'].to_i if ENV['DESKPRO_TEAM_ID']
		if not @ticket.valid?
			@errors = @ticket.errors
			status 400
			erb :'contact-us'
		else
			begin
				deskpro.post @ticket
				@msg = "We’ll contact you in the next working day"
				erb :thanks
			rescue => ex
				status 500
				@errors[:fatal] = [ex.to_s]
				erb :'contact-us'
			end
		end
	end

	get '/signup' do
		@errors = {}
		@form = Forms::Signup.new({
			:person_is_manager => true,
			:invites => 3.times.map{ Forms::Invite.new({
				:person_email => '',
				:person_is_manager => false
			}) }
		})
		erb :signup
	end

	post '/signup' do
		@errors = {}
		@form = Forms::Signup.new({
			:person_email => params[:person_email] || '',
			:person_name => params[:person_name] || '',
			:person_is_manager => params[:person_is_manager] == 'true',
			:department_name => params[:department_name] || '',
			:service_name => params[:service_name] || '',
			:invite_users => params[:invite_users] == 'true',
			:invites => (params[:invites] || {'0': {:person_email => '', :person_is_manager => false}}).map{ |indexKey, invite|
				Forms::Invite.new({
					:person_email => invite[:person_email] || '',
					:person_is_manager => invite[:person_is_manager] == 'true',
				})
			}.reject{|invite| invite.person_email.empty? }
		})
		if not @form.valid?
			@errors = @form.errors
			status 400
			return erb :signup
		else
			begin
				deskpro.post @form.to_ticket
				@msg = "We’ll email you with your organisation account details in the next working day."
				erb :thanks
			rescue => ex
				status 500
				@errors[:fatal] = [ex.to_s]
				erb :signup
			end
		end
	end

	get '/*' do
		# check for asset
		res = settings.sprockets.call(env)
		return res if res && res[0] != 404
		# check for a view name
		path = params[:splat].first
		viewname = path.sub(/\.html$/, '')
		return not_found if !File.exist?("views/#{viewname}.erb")
		# strip .html ext
		return redirect("/#{viewname}", 301) if path.match?(/\.html/)
		# render erb page
		content_type 'text/html;charset=utf8'
		erb viewname.to_sym
	end

	not_found do
		content_type 'text/html;charset=utf8'
		erb :not_found
	end

	error do
		@error = env['sinatra.error']
		erb :error
	end

	helpers do

		# create a deskpro client
		def deskpro
			Deskpro::Client.new(
				api_key: ENV['DESKPRO_API_KEY'],
				endpoint: ENV['DESKPRO_ENDPOINT']
			)
		end

	end

end
