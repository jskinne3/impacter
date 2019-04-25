class DoorsController < ApplicationController
  before_action :authenticate_user!

  def new
    @door = Door.new
    @zips = Door.select(:zip).map(&:zip).compact.uniq.sort
  end

  def create
    if params[:commit] == 'Survey'
      redirect_to controller: 'knocks', action: 'new'
    else
      render html: 'Community convo form will go here...'
    end
=begin
    @door = Door.new(door_params)

    respond_to do |format|
      if @door.save
        format.html { redirect_to @door, notice: 'Door was successfully created.' }
        format.json { render :show, status: :created, location: @door }
      else
        format.html { render :new }
        format.json { render json: @door.errors, status: :unprocessable_entity }
      end
    end
=end
  end

  
end
