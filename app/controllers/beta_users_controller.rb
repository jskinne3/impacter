class BetaUsersController < ApplicationController
  before_action :authenticate_user!, except: [:new, :create]

	def index
    @beta_users = BetaUser.all
  end

  def new
  	@beta_user = BetaUser.new
  end

  def create
    @beta_user = BetaUser.new(beta_user_params)

    respond_to do |format|
      if @beta_user.save
        format.html { redirect_to root_path, notice: 'Someone will contact you! Thanks!' }
      else
        format.html { render :new }
      end
    end
  end

  private

  def beta_user_params
    params.require(:beta_user).permit(:email, :goals)
  end

end
