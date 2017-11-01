require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'sprockets'
require 'sinatra/sprockets-helpers'
require 'erubis'

# App is the main Sinatra application
class App < Sinatra::Base
	set :sprockets, Sprockets::Environment.new
	set :title, 'GOV.UK Platform as a Service'
	set :erb, :escape_html => true

	# IMPORTANT: The app does not have CSRF protection enabled and if
	# you need sessions you should set that up appropriately using
	# Rack::Protection.
	set :sessions, false

	# Critical protection against Path Traversal.
	use Rack::Protection::PathTraversal

	# Protection to limit potential XSS attacks and effects.
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
			config.debug = true if development?
			config.prefix = "/"
			config.environment = sprockets
		end
		register Sinatra::Reloader if development?
	end

	helpers Sinatra::ContentFor
	helpers Sprockets::Helpers

	get '/?' do
		erb :index
	end

	get '/*' do
		path = params[:splat].first

		# Check for a relevant erb template
		view_name = path.sub(/\.html$/, '')
		# Protected against directory traversal by Rack::Protection::PathTraversal
		# We also restrict view names to alphanumeric, dash and underscore characters.
		# These are definitively safe against being used for directory traversal/etc.
		if !/[^a-zA-Z0-9_-]/.match(view_name)
			# Check for an appropriately-named view
			if File.exist? "views/#{view_name}.erb"
				# Strip `.html` extension if present
				if path.match?(/\.html/)
					return redirect("/#{view_name}", 301)
				end

				# Render the view's erb template
				content_type 'text/html;charset=utf8'
				return erb(view_name.to_sym)
			end
		end

		# Check for an appropriately-named Sprocket asset
		res = settings.sprockets.call(env)
		return res if res && res[0] != 404

		# Return 404 Not Found
		not_found
	end

	not_found do
		content_type 'text/html;charset=utf8'
		erb :not_found
	end

	error do
		if settings.development?
			@error = env['sinatra.error']
		end
		content_type 'text/html;charset=utf8'
		erb :error
	end
end
