class Admin::ChaptersController < ApplicationController
  before_action :set_chapter, only: %i[ show edit update destroy ]

  # GET /chapters or /chapters.json
  def index
    @chapters = Chapter.order(:name)
  end

  # GET /chapters/1 or /chapters/1.json
  def show
    render json: [@chapter] if params[:wrap] == 'true'
  end

  # GET /chapters/new
  def new
    @chapter = Chapter.new
  end

  # GET /chapters/1/edit
  def edit
  end

  # POST /chapters or /chapters.json
  def create
    @chapter = Chapter.new(chapter_params)

    respond_to do |format|
      if @chapter.save
        format.html { redirect_to admin_chapter_url(@chapter), notice: "Chapter was successfully created." }
        format.json { render :show, status: :created, location: @chapter }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chapters/1 or /chapters/1.json
  def update
    respond_to do |format|
      if @chapter.update(chapter_params)
        format.html { redirect_to admin_chapter_url(@chapter), notice: "Chapter was successfully updated." }
        format.json { render :show, status: :ok, location: @chapter }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @chapter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chapters/1 or /chapters/1.json
  def destroy
    @chapter.destroy

    respond_to do |format|
      format.html { redirect_to admin_chapters_url, notice: "Chapter was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chapter
      @chapter = Chapter.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chapter_params
      params.fetch(:chapter, {}).permit(:name, :institution_name, :location, :website, :slc, :region_id, :district_id, :longitude, :latitude)
    end
end