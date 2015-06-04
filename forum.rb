require "sinatra/base"
require "sinatra/reloader"
require "pry"
require_relative "models/objects"

module Forum

	$message_new = ""
	$message_login = ""

	class Server < Sinatra::Base

		include Models

		configure do
      register Sinatra::Reloader
      set :sessions, true
    end

    get('/') do
    	@message_new = $message_new
    	erb :homepage
    end

    post('/user/new') do
    	$message_new = ""
			$message_login = ""
    	if (params[:fname].length == 0)
    		$message_new = "Please enter a first name"
    		redirect '/'
    	elsif (params[:lname].length == 0)
    	 	$message_new = "Please enter a last name"
    		redirect '/'
    	elsif ((params[:email].length == 0) || (!params[:email].include?('@')) || (!params[:email].include?('.')))
    		$message_new = "Please enter a valid e-mail"
    		redirect '/'
    	elsif (params[:pwd1].length == 0)
    		$message_new = "Please enter a valid password"
    		redirect '/'
    	elsif (params[:pwd1] != params[:pwd2])
    		$message_new = "Passwords don't match"
    		redirect '/'
    	else
	    	@user = User.createNew(params[:fname], params[:lname], params[:email], params[:pwd1])
	    	if (@user.nil?)
	    		$message_new = "A user with this e-mail already exists. Please try again."
	    		redirect '/'
	    	else
	    		erb :userpage
	    	end
	    end

    end


	end

end