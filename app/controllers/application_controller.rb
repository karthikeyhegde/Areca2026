  class ApplicationController < ActionController::Base
  protect_from_forgery
  before_action :authorize, :clear_thread ,:accessable


  private

  def clear_thread
  end  

  def authorize
        params.permit!
        if session[:user_id].nil?
            redirect_to :controller => 'users', :action => 'ask_signin'
            return
        end 

        @auser = User.find(session[:user_id])
        if (@auser.active == 0 || @auser.active = false)
          Thread.current[:auser] = nil
          session[:user_id] = nil
          redirect_to :controller => 'users', :action => 'ask_signin'
          return
        end

        Thread.current[:auser] = nil
        User.current_user= @auser
  end	

  def accessable
=begin    
    p "Params xxxx"
    p params
    ra = RoleAccess.where("role = ? and controller = ? and action = ? and allow = 0 ",@auser.role,params[:controller],params[:action])
    redirect_to :controller => 'users', :action => 'no_access' if ra.size > 0
=end
  end  



end
