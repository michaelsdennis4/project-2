require "pry"
require "redcarpet"
require "rest-client"
require_relative "../db/connection"

module Methods

	include RestClient

	def self.getLocation(ip_address)
		response = RestClient.get("ipinfo.io/#{ip_address}/geo")
    data = JSON.parse(response)
    @location = "#{data['city']}, #{data['region']}, #{data['country']}"
	end

end

module Models

	class User 

		attr_reader :id, :signed_up_on
		attr_writer :password
	  attr_accessor :fname, :lname, :email, :gender, :image,
									:phone, :show_location, :get_notifications, :bio, :active

		def initialize(id, fname, lname, email, password, signed_up_on)
			@id = id
			@fname = fname
			@lname = lname
			@email = email
			@password = password
			@signed_up_on = signed_up_on
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
			query = "INSERT INTO users (fname, lname, email, password, signed_up_on,
			 				show_location, active)
							VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP, $5, 't')
							RETURNING id, signed_up_on";
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
				query = "UPDATE users SET active='t' WHERE id=$1"
				$db.exec_params(query, [user_id])
				user_id
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
				userObject.active = user['active']
				userObject
			end
		end

		def self.findAll
			query = "SELECT * FROM users WHERE (id > 1 AND active='t') ORDER BY lname, fname"
			results = $db.exec(query)
			users = []
			results.each do |user|
				userObject = User.new(user['id'], user['fname'], user['lname'], user['email'],
								user['password'], user['signed_up_on'])
				userObject.gender = user['gender']
				userObject.phone = user['phone']
				userObject.image = user['image']
				userObject.show_location = user['show_location']
				userObject.get_notifications = user['get_notifications']
				userObject.bio = user['bio']
				users.push(userObject)
			end
			users
		end

		def name
			"#{@fname} #{@lname}"
		end

		def update(params)
			query = "UPDATE users SET fname=$1, lname=$2, email=$3, gender=$4, image=$5,
							phone=$6, show_location=$7, get_notifications=$8 WHERE id=$9"
			if (params[:show_location])
				loc = "t"
			else
				loc = "f"
			end
			qparams = [params[:fname], params[:lname], params[:email], params[:gender],
								params[:image], params[:phone], loc, params[:get_notifications], @id]
			$db.exec_params(query, qparams)
		end

		def changePassword(old_pass, new_pass)
			if (old_pass == @password)
				query = "UPDATE users SET password=$1 WHERE id=$2"
				qparams = [new_pass, @id]
				$db.exec_params(query, qparams)
				true
			else
				false
			end
		end

		def delete
			query = "UPDATE users SET active='f' WHERE id=$1"
			$db.exec_params(query, [@id])
		end

	end

	class Topic

		include Methods, Redcarpet

		attr_reader :id, :created_on, :owner_id
		attr_writer :user_location
		attr_accessor :subject, :owner_name, :details, :details_md,  
									:num_comments, :total_score, :show_location, :user_active 

		def initialize(id, owner_id, subject, details, created_on, user_location)
			@id = id
			@owner_id = owner_id
			@subject = subject
			markdown = Markdown.new(Redcarpet::Render::HTML, extensions = {})
			@details = details
			@details_md = markdown.render(details)
			@created_on = created_on
			@user_location = user_location
		end

		def self.createNew(params, user_id, ip_address)
			location = Methods.getLocation(ip_address)
			query = "INSERT INTO topics (owner_id, subject, details, created_on, user_location)
							VALUES ($1, $2, $3, CURRENT_TIMESTAMP, $4) RETURNING id";
			qparams = [user_id, params[:subject], params[:details], location]
			result = $db.exec_params(query, qparams)
			topic_id = result.entries.first['id']
			# create dummy vote object
			query = "INSERT INTO votes (owner_id, topic_id, score)
							VALUES ($1, $2, $3)"
			qparams = [1, topic_id, 0]
			$db.exec_params(query, qparams)
			topic_id
		end

		def self.find(id)
			query = "SELECT topics.*, users.fname AS fname, users.lname AS lname,
							users.show_location AS show_location, users.active AS active,
							count(comments.id) AS num_comments, sum(votes.score) AS total_score 
							FROM topics INNER JOIN users ON users.id = topics.owner_id
							LEFT JOIN comments ON comments.topic_id = topics.id
							LEFT JOIN votes ON votes.topic_id = topics.id
							WHERE topics.id=$1
							GROUP BY topics.id, users.fname, users.lname, users.show_location, users.active"
			result = $db.exec_params(query, [id.to_i])
			topic = result.first
			if (topic == nil)
				nil
			else
				topicObject = Topic.new(topic['id'], topic['owner_id'], topic['subject'], topic['details'], topic['created_on'], topic['user_location'])
				topicObject.owner_name = "#{topic['fname']} #{topic['lname']}"
				topicObject.num_comments = topic['num_comments']
				topicObject.total_score = topic['total_score']
				topicObject.show_location = topic['show_location']
				topicObject.user_active = topic['active']
				topicObject
			end
		end

		def self.findAll(sort_by)
			query = "SELECT topics.*, users.fname AS fname, users.lname AS lname,
							users.show_location AS show_location, users.active AS active,
							count(comments.id) AS num_comments, sum(votes.score) AS total_score 
							FROM topics INNER JOIN users ON users.id = topics.owner_id
							LEFT JOIN comments ON comments.topic_id = topics.id
							LEFT JOIN votes ON votes.topic_id = topics.id
							GROUP BY topics.id, users.fname, users.lname, users.show_location, users.active"
			if (sort_by == "recent")
				query << " ORDER BY topics.created_on DESC"
			elsif (sort_by == "comments")
				query << " ORDER BY num_comments DESC"
			elsif (sort_by == "popular")
				query << " ORDER BY total_score DESC" 
			end
			results = $db.exec(query)
			topics = []
			results.each do |topic|
				topicObject = Topic.new(topic['id'], topic['owner_id'], topic['subject'], topic['details'], topic['created_on'], topic['user_location'])
				topicObject.owner_name = "#{topic['fname']} #{topic['lname']}"
				topicObject.num_comments = topic['num_comments']
				topicObject.total_score = topic['total_score']
				topicObject.show_location = topic['show_location']
				topicObject.user_active = topic['active']
				topics.push(topicObject)
			end
			topics
		end

		def self.findByUser(user_id, sort_by)
			query = "SELECT topics.*, users.fname AS fname, users.lname AS lname,
							users.show_location AS show_location, users.active AS active,
							count(comments.id) AS num_comments, sum(votes.score) AS total_score 
							FROM topics INNER JOIN users ON users.id = topics.owner_id
							LEFT JOIN comments ON comments.topic_id = topics.id
							LEFT JOIN votes ON votes.topic_id = topics.id
							WHERE users.id=$1
							GROUP BY topics.id, users.fname, users.lname, users.show_location, users.active"
			if (sort_by == "recent")
				query << " ORDER BY topics.created_on DESC"
			elsif (sort_by == "comments")
				query << " ORDER BY num_comments DESC"
			elsif (sort_by == "popular")
				query << " ORDER BY total_score DESC" 
			end
			results = $db.exec_params(query, [user_id])
			topics = []
			results.each do |topic|
				topicObject = Topic.new(topic['id'], topic['owner_id'], topic['subject'], topic['details'], topic['created_on'], topic['user_location'])
				topicObject.owner_name = "#{topic['fname']} #{topic['lname']}"
				topicObject.num_comments = topic['num_comments']
				topicObject.total_score = topic['total_score']
				topicObject.show_location = topic['show_location']
				topicObject.user_active = topic['active']
				topics.push(topicObject)
			end
			topics
		end

		def update(params)
			query = "UPDATE topics SET subject=$1, details=$2 WHERE id=$3"
			qparams = [params[:subject], params[:details], @id]
			$db.exec_params(query, qparams)
		end

		def delete
			query = "DELETE FROM votes WHERE topic_id=$1"
			$db.exec_params(query, [@id])
			query = "DELETE FROM comments WHERE topic_id=$1"
			$db.exec_params(query, [@id])
			query = "DELETE FROM topics WHERE id=$1"
			$db.exec_params(query, [@id])
		end

		def user_location
			if (@show_location == 't')
				@user_location
			else
				""
			end
		end			

	end

	class Comment

		include Methods

		attr_reader :id, :created_on, :owner_id, :topic_id
		attr_writer :user_location
		attr_accessor :show_location, :owner_name, :details

		def initialize(id, owner_id, topic_id, details, created_on, user_location)
			@id = id
			@owner_id = owner_id
			@topic_id = topic_id
			@details = details
			@created_on = created_on
			@user_location = user_location
		end

		def self.createNew(params, user_id, ip_address)
			location = Methods.getLocation(ip_address)
			query = "INSERT INTO comments (owner_id, topic_id, details, created_on, user_location)
							VALUES ($1, $2, $3, CURRENT_TIMESTAMP, $4) RETURNING id";
			qparams = [user_id, params[:topic_id], params[:details], location]
			result = $db.exec_params(query, qparams)
			comment_id = result.entries.first['id']
		end

		def self.find(id)
			query = "SELECT comments.*, users.fname AS fname, users.lname AS lname, 
							users.show_location AS show_location FROM comments
							INNER JOIN users ON users.id = comments.owner_id WHERE comments.id=$1"
			result = $db.exec_params(query, [id.to_i])
			comment = result.first
			if (comment == nil)
				nil
			else
				commentObject = Comment.new(comment['id'], comment['owner_id'], comment['details'], comment['details'], comment['created_on'], comment['user_location'])
				commentObject.owner_name = "#{comment['fname']} #{comment['lname']}"
				commentObject.show_location = comment['show_location']
				commentObject
			end
		end

		def self.findByTopic(topic_id)
			query = "SELECT comments.*, users.fname AS fname, users.lname AS lname,
			 				users.show_location AS show_location FROM comments
							INNER JOIN users ON users.id = comments.owner_id 
							INNER JOIN topics ON topics.id = comments.topic_id
							WHERE topics.id=$1 ORDER BY comments.created_on DESC"
			results = $db.exec_params(query, [topic_id])
			comments = []
			results.each do |comment|
				commentObject = Comment.new(comment['id'], comment['owner_id'], comment['details'], comment['details'], comment['created_on'], comment['user_location'])
				commentObject.owner_name = "#{comment['fname']} #{comment['lname']}"
				commentObject.show_location = comment['show_location']
				comments.push(commentObject)
			end
			comments
		end

		def update(params)
			query = "UPDATE comments SET details=$1 WHERE id=$2"
			qparams = [params[:details], @id]
			results = $db.exec_params(query, qparams)
		end

		def delete
			query = "DELETE FROM comments WHERE id=$1"
			$db.exec_params(query, [@id])
		end

		def user_location
			if (@show_location == 't')
				@user_location
			else
				""
			end
		end

	end

	class Vote

		attr_reader :id, :owner_id, :topic_id
		attr_accessor :score

		def initialize(id, owner_id, topic_id, score)
			@id = id
			@owner_id = owner_id
			@topic_id = topic_id
			@score = score
		end

		def self.createNew(params, user_id)
			query = "INSERT INTO votes (owner_id, topic_id, score)
							VALUES ($1, $2, $3)"
			qparams = [user_id, params[:topic_id], params[:score]]
			$db.exec_params(query, qparams)
		end

		def self.find(user_id, topic_id)
			query = "SELECT * FROM votes WHERE owner_id=$1 AND topic_id=$2"
			qparams = [user_id, topic_id]
			result = $db.exec_params(query, qparams)
			vote = result.first
			if (vote == nil)
				nil
			else
				voteObject = Vote.new(vote['id'], vote['owner_id'], vote['topic_id'], vote['score'])
			end
		end

		def update(score)
			query = "UPDATE votes SET score=$1 WHERE owner_id=$2 AND topic_id=$3"
			qparams = [score, @owner_id, @topic_id]
			$db.exec_params(query, qparams)
		end

	end

end
