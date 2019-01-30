class UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /knocks
  # GET /knocks.json
  def index
    @users = User.all
  end

end
