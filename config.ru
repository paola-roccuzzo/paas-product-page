require 'rubygems'
require 'bundler'

Bundler.require

require 'sinatra'
configure do
	set :server, :puma
end

require './app'
run App
