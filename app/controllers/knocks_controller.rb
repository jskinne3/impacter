class KnocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_knock, only: [:show, :edit, :update, :destroy]

  # GET /knocks
  # GET /knocks.json
  def index
    @knocks = Knock.all.includes(:door).includes(:canvasser)
  end

  def search
    # set up search form options
    @canvassers = Canvasser.all
    @neighborhoods = Knock.select(:neighborhood).map(&:neighborhood).uniq
    @years = (Date.today.year-5..Date.today.year).to_a.reverse
    # if the user is asking for a text search
    unless params[:q].blank?
      results = Answer.search(params[:q])
      @questions = Question.where(id: results.map{|r| r.try(:question_id)}.uniq)
      @answers = results.group_by{|r| r.try(:knock_id)}
      knock_ids = @answers.map{|id,v| id}
    end
    # build query from what the user has asked for
    @knocks = Knock.all
    @knocks = @knocks.where(id: knock_ids) if knock_ids
    @knocks = @knocks.where(canvasser_id: params[:canvasser][:id]) unless params[:canvasser][:id].blank? if params[:canvasser]
    @knocks = @knocks.where(neighborhood: params[:neighborhood]) unless params[:neighborhood].blank?
    unless params[:year].blank?
      @knocks = @knocks.where(when: Date.new(params[:year].to_i)..Date.new(params[:year].to_i).end_of_year)
    end
  end

  # GET /knocks/1
  # GET /knocks/1.json
  def show
    @answers = @knock.answers.reverse
  end

  # GET /knocks/new
  def new
    @knock = Knock.new
  end

  # GET /knocks/1/edit
  def edit
  end

  # POST /knocks
  # POST /knocks.json
  def create
    @knock = Knock.new(knock_params)

    respond_to do |format|
      if @knock.save
        format.html { redirect_to @knock, notice: 'Knock was successfully created.' }
        format.json { render :show, status: :created, location: @knock }
      else
        format.html { render :new }
        format.json { render json: @knock.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /knocks/1
  # PATCH/PUT /knocks/1.json
  def update
    respond_to do |format|
      if @knock.update(knock_params)
        format.html { redirect_to @knock, notice: 'Knock was successfully updated.' }
        format.json { render :show, status: :ok, location: @knock }
      else
        format.html { render :edit }
        format.json { render json: @knock.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /knocks/1
  # DELETE /knocks/1.json
  def destroy
    @knock.destroy
    respond_to do |format|
      format.html { redirect_to knocks_url, notice: 'Knock was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_knock
      @knock = Knock.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def knock_params
      params.fetch(:knock, {})
    end
end
