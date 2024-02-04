# frozen_string_literal: true

module Admin
  class RegionsController < ApplicationController
    before_action :set_region, only: %i[show edit update destroy chapters]

    # GET /regions or /regions.json
    def index
      @regions = Region.order(:position)
      return unless params[:format] == 'csv'

      send_data Region.generate_csv, filename: 'regions.csv'
    end

    # GET /regions/1 or /regions/1.json
    def show
      @manpower_survey = []
      @region.chapters.each do |c|
        record = { name: c.name, data: {} }
        c.manpower_surveys.each do |s|
          record[:data][s.survey_date] = s.manpower
        end
        @manpower_survey << record
      end
    end

    # GET /regions/new
    def new
      @region = Region.new
    end

    # GET /regions/1/edit
    def edit; end

    # POST /regions or /regions.json
    def create
      @region = Region.new(region_params)

      respond_to do |format|
        if @region.save
          format.html { redirect_to admin_region_url(@region), notice: 'Region was successfully created.' }
          format.json { render :show, status: :created, location: @region }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @region.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /regions/1 or /regions/1.json
    def update
      respond_to do |format|
        if @region.update(region_params)
          format.html { redirect_to admin_region_url(@region), notice: 'Region was successfully updated.' }
          format.json { render :show, status: :ok, location: @region }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @region.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /regions/1 or /regions/1.json
    def destroy
      @region.destroy

      respond_to do |format|
        format.html { redirect_to admin_regions_url, notice: 'Region was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    # GET /regions/1/chapters or /regions/1/chapters.json
    def chapters
      respond_to do |format|
        format.html { render template: 'chapters/index', locals: { '@chapters': @region.chapters } }
        format.json { render template: 'chapters/index', locals: { '@chapters': @region.chapters } }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_region
      @region = Region.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def region_params
      params.fetch(:region, {}).permit(:name, :short_name, :position)
    end
  end
end
