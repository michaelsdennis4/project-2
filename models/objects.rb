require "pry"
require_relative "../db/connection"

module Models

	class User 

		attr_reader :id

		attr_accessor :fname, :lname, :email, :password, :signed_up_on, :gender, :image,
									:phone, :show_location, :get_notifications, :bio

		def initialize(id, fname, lname, email, password, signed_up_on)
			@id = id
			@fname = fname
			@lname = lname
			@email = email
			@password = password
			@signed_up_on = signed_up_on
		end

		def name
			@fname + ' ' + @lname
		end

		def self.validate(params)
			errors = []
			if (params[:fname].length == 0)
    		errors.push("Please enter a first name")
    	end
    	if (params[:lname].length == 0)
    	 	errors.push("Please enter a last name")
   		end
    	if ((params[:email].length == 0) || (!params[:email].include?('@')) || (!params[:email].include?('.')))
    		errors.push("Please enter a valid e-mail")
    	end
    		# redirect '/'
    	if (params[:pwd1].length == 0)
    		errors.push("Please enter a valid password")
    	end
    		# redirect '/'
    	if (params[:pwd1] != params[:pwd2])
    		errors.push("Passwords don't match")
    	end
    	# check to make sure user with same e-mail doesn't already exist
			query = "SELECT count(*) AS count FROM users WHERE email=$1"
			result = $db.exec_params(query, [params[:email]])
			count = result.first['count'].to_i
			if (count > 0)
				errors.push("A user with this e-mail already exists. Please try again.")
    	end
    	errors
		end

		def self.createNew(params)
			query = "INSERT INTO users (fname, lname, email, password, signed_up_on, show_location)
							VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, $5) RETURNING id, signed_up_on";
			qparams = [params[:fname], params[:lname], params[:email], params[:pwd1], 'f']
			result = $db.exec_params(query, qparams)
			user_id = result.entries.first['id']
		end

		def self.login(params)
			query = "SELECT id FROM users WHERE email=$1 AND password=$2";
			qparams = [params[:email], params[:password]]
			result = $db.exec_params(query, qparams)
			user = result.first
			if (user == nil)
				user_id = nil
			else
				user_id = user['id']
			end
		end

		def self.find(id)
			query = "SELECT * FROM users WHERE id=$1"
			result = $db.exec_params(query, [id.to_i])
			user = result.first
			if (user == nil)
				nil
			else
				userObject = User.new(user['id'], user['fname'], user['lname'], user['email'],
								user['password'], user['signed_up_on'])
				userObject.gender = user['gender']
				userObject.phone = user['phone']
				userObject.image = user['image']
				userObject.show_location = user['show_location']
				userObject.get_notifications = user['get_notifications']
				userObject.bio = user['bio']
				userObject
			end
		end


	end


end
