# frozen_string_literal: true

module Admin
  class ChaptersController < ApplicationController
    before_action :set_chapter, only: %i[show edit update destroy]
    before_action -> { require_role(:editor) }, only: %i[new edit create update destroy import do_import]

    # GET /chapters or /chapters.json
    def index
      @chapters = Chapter.all
      @chapters_missing_district = Chapter.active.where(district: nil)
      return unless params[:format] == 'csv'

      send_data Chapter.as_csv(@chapters), filename: 'chapters.csv'
    end

    # GET /chapters/1 or /chapters/1.json
    def show
      render json: [@chapter] if params[:wrap] == 'true'
      @manpower_survey = {}
      @chapter.manpower_surveys.each do |s|
        @manpower_survey[s.survey_date.strftime('%Y-%m-%d')] = s.manpower
      end
    end

    # GET /chapters/new
    def new
      @chapter = Chapter.new
    end

    # GET /chapters/1/edit
    def edit; end

    # POST /chapters or /chapters.json
    def create
      @chapter = Chapter.new(chapter_params)

      respond_to do |format|
        if @chapter.save
          format.html { redirect_to admin_chapter_url(@chapter), notice: 'Chapter was successfully created.' }
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
          format.html { redirect_to admin_chapter_url(@chapter), notice: 'Chapter was successfully updated.' }
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
        format.html { redirect_to admin_chapters_url, notice: 'Chapter was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    def import; end

    def do_import
      uploaded_file = params[:file]
      raise 'No file provided' if uploaded_file.nil?

      csv = CSV.parse(uploaded_file.read, headers: true)

      # Process Chapter Updates
      csv.each do |row|
        district = District.find_or_create_by(short_name: row['district']) unless row['District'].nil?
        if district && district.new_record?
          district.name = "District #{row['District']}" if district.name.nil?
          district.short_name = (row['District']).to_s if district.short_name.nil?
          district.position = row['District'].to_i if district.position.zero?
          district.save!
        end

        chapter = Chapter.find_or_create_by(name: row['Chapter'])
        chapter.chapter_roll = row['Roll #'] unless row['Roll #'].nil?
        chapter.name = row['Chapter']
        chapter.institution_name = row['Institution Name'] unless row['Institution Name'].nil?
        chapter.status = row['Status'] == 'Active' unless row['Status'].nil?
        chapter.slc = row['SLC?'] == 'Yes' unless row['SLC?'].nil?
        chapter.expansion = row['Expansion?'] == 'Yes' unless row['Expansion'].nil?
        chapter.city = row['City'] unless row['City'].nil?
        chapter.state = row['State'] unless row['State'].nil?
        chapter.latitude = row['Latitude'] unless row['Latitude'].nil?
        chapter.longitude = row['Longitude'] unless row['Longitude'].nil?
        chapter.charter_date = Date.strptime(row['Charter Date'], '%Y-%m-%d').strftime('%Y-%m-%d') unless row['Charter Date'].nil?
        chapter.district = district unless district.nil?
        chapter.website = row['Website'] unless row['Website'].nil?
        chapter.save!
      end

      flash[:notice] = 'Upload complete!'
      redirect_to(admin_chapters_url)
    rescue CSV::MalformedCSVError => e
      flash[:error] = "Parsing Error: #{e}"
      redirect_to(admin_chapters_import_url)
    rescue StandardError => e
      flash[:error] = e.to_s
      redirect_to(admin_chapters_import_url)
    end

    def map
      @districts = District.all
      @chapters = Chapter.all.order(:name)
      @chapters = Chapter.all.search(params[:q], true) unless params[:q].blank?
      @chapters = District.find(params[:district_id]).chapters.all unless params[:district_id].blank?
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_chapter
      @chapter = Chapter.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def chapter_params
      params.fetch(:chapter, {}).permit(:name, :institution_name, :city, :state, :website, :slc, :status,
                                        :expansion, :district_id, :longitude, :latitude, :charter_date,
                                        :chapter_roll)
    end
  end
end
