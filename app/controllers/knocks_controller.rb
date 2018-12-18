class KnocksController < ApplicationController
  before_action :set_knock, only: [:show, :edit, :update, :destroy]

  # GET /knocks
  # GET /knocks.json
  def index
    @knocks = Knock.all.includes(:door).includes(:canvasser)
  end

  def search
    if params[:q]
      results = Answer.search(params[:q])
      @questions = Question.where(id: results.map{|r| r.try(:question_id)}.uniq)
      @answers = results.group_by{|r| r.try(:knock_id)}
      knock_ids = @answers.map{|id,v| id}
      @knocks = Knock.where(id: knock_ids)
    end
  end

  # GET /knocks/1
  # GET /knocks/1.json
  def show
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
