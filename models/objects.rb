require "pry"
require_relative "../db/connection"

module Models

	class User 

		attr_reader :id

		attr_accessor :fname, :lname, :email, :password, :signed_up_on, :gender, :image,
									:phone, :show_location, :get_notifications

		def self.createNew(fname, lname, email, password)
			# check to make sure user with same e-mail doesn't already exist
			query = "SELECT count(*) AS count FROM users WHERE email=$1"
			result = $db.exec_params(query, [email])
			count = result.first['count'].to_i
			if (count > 0)
				nil
			else
				query = "INSERT INTO users (fname, lname, email, password, signed_up_on, show_location)
								VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, $5) RETURNING id, signed_up_on";
				params = [fname, lname, email, password, 'f']
				result = $db.exec_params(query, params)
				new_id = result.entries.first['id']
				signed_up = result.entries.first['signed_up_on']
				new_user = User.new(new_id, fname, lname, email, password, signed_up)
				new_user
			end
		end

		def initialize(id, fname, lname, email, password, signed_up_on)
			@id = id
			@fname = fname
			@lname = lname
			@email = email
			@password = password
			@signed_up_on = signed_up_on
		end

	end


end
