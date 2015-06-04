require "sinatra/base"
require "sinatra/reloader"
require "pry"

module Forum

	class Server < Sinatra::Base

		configure do
      register Sinatra::Reloader
      set :sessions, true
    end

    get('/') do
    	erb :homepage
    end


	end

end