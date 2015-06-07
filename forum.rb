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
      @sort = "recent"
      @topics = Topic.findByUser(params[:id], @sort)
    	erb :userpage
    end

    post('/users/login') do
    	user_id = User.login(params)
    	if (user_id == nil)
    		@errors = []
    		@error = "Login failed. Try again."
    		erb :homepage
    	else
    		session[:user_id] = user_id
	   		# redirect "/users/#{current_user}"
        redirect "/hub"
	   	end
    end

    delete('/users/login') do
      session[:user_id] = nil
      redirect '/'
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

    post('/users/:id') do
      @current_user_name = User.find(current_user).name
      @user = User.find(params[:id])
      @sort = params[:sort]
      @topics = Topic.findByUser(params[:id], @sort)
      erb :userpage
    end

    patch('/users/pass/:id') do
      user = User.find(params[:id])
      @result = user.changePassword(params[:old_pass], params[:new_pass])
      @current_user_name = User.find(current_user).name
      @user = User.find(params[:id])
      @sort = "recent"
      @topics = Topic.findByUser(params[:id], @sort)
      erb :userpage
    end

    patch('/users/:id') do
      user = User.find(params[:id])
      user.update(params)
      redirect "/users/#{params[:id]}"
    end

    delete('/users/:id') do
      user = User.find(params[:id])
      user.delete
      redirect "/"
    end

    get('/hub') do
      @current_user_name = User.find(current_user).name
      @users = User.findAll
      @sort = "recent" #default
      @topics = Topic.findAll(@sort)
      erb :hub
    end

    post('/hub') do
      @current_user_name = User.find(current_user).name
      @users = User.findAll
      @sort = params[:sort]
      @topics = Topic.findAll(@sort)
      erb :hub
    end

    get('/topics/new') do
      @current_user_name = User.find(current_user).name
      @topic = nil
      erb :topicpage
    end

    post('/topics/new') do
      # ip = request.ip
      ip = "96.232.165.39"
      topic_id = Topic.createNew(params, current_user, ip)
      redirect "/topics/#{topic_id}"
    end

    get('/topics/edit/:id') do
      @current_user_name = User.find(current_user).name
      @topic = Topic.find(params[:id])
      @comments = Comment.findByTopic(params[:id])
      @vote = Vote.find(current_user, params[:id])
      @edit = true;
      erb :topicpage
    end

    get('/topics/:id') do
      @current_user_name = User.find(current_user).name
      @topic = Topic.find(params[:id])
      @comments = Comment.findByTopic(params[:id])
      @vote = Vote.find(current_user, params[:id])
      @edit = false;
      erb :topicpage
    end

    patch('/topics/:id') do
      @topic = Topic.find(params[:id])
      @topic.update(params)
      redirect "/topics/#{@topic.id}"
    end

    delete('/topics/:id') do
      @topic = Topic.find(params[:id])
      @topic.delete
      redirect "/hub"
    end

    post('/comments/new/:topic_id') do
      # ip = request.ip
      ip = "96.232.165.39"
      Comment.createNew(params, current_user, ip)
      redirect "/topics/#{params[:topic_id]}"
    end

    patch('/comments/:id/:topic_id') do
      comment = Comment.find(params[:id])
      comment.update(params)
      redirect "/topics/#{params[:topic_id]}"
    end

    delete('/comments/:id/:topic_id') do
      comment = Comment.find(params[:id])
      comment.delete
      redirect "/topics/#{params[:topic_id]}"
    end

    post('/votes/:topic_id') do
      vote = Vote.find(current_user, params[:topic_id])
      if (vote)
        vote.update(params[:score])
      else
        Vote.createNew(params, current_user)
      end
      redirect "/topics/#{params[:topic_id]}"
    end


	end

end