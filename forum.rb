require "sinatra/base"
require "sinatra/reloader"
require "pry"
require_relative "models/objects"

module Forum

	class Server < Sinatra::Base

		include Models

		configure do
      register Sinatra::Reloader
      set :sessions, true
    end

    def current_user
      session[:user_id]
    end

    def logged_in?
      !current_user.nil?
    end

    get('/') do
    	@errors = []
    	erb :homepage
    end

    get('/users/:id') do
    	@current_user_name = User.find(current_user).name
    	@user = User.find(params[:id])
    	erb :userpage
    end

    post('/users/login') do
    	user_id = User.login(params)
    	if (user_id == nil)
    		@errors = []
    		@error = "Login failed."
    		erb :homepage
    	else
    		session[:user_id] = user_id
	   		redirect "/users/#{current_user}"
	   	end
    end

    post('/users/new') do
  		@errors = User.validate(params)
  		if (@errors.any?)
  			erb :homepage
  		else
				user_id = User.createNew(params)
	   		session[:user_id] = user_id
	   		redirect "/users/#{current_user}"
    	end
    end

	end

end