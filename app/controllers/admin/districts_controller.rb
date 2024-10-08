# frozen_string_literal: true

module Admin
  class DistrictsController < ApplicationController
    before_action :set_district, only: %i[show edit update destroy chapters]
    before_action -> { require_role(:editor) }, only: %i[new edit create update destroy]


    # GET /districts or /districts.json
    def index
      @districts = District.order(:position)
      return unless params[:format] == 'csv'

      send_data District.generate_csv, filename: 'districts.csv'
    end

    # GET /districts/1 or /districts/1.json
    def show
      @manpower_survey = []
      @district.chapters.active.each do |c|
        record = { name: c.name, data: {} }
        c.manpower_surveys.each do |s|
          record[:data][s.survey_date] = s.manpower
        end
        @manpower_survey << record
      end
    end

    # GET /districts/new
    def new
      @district = District.new
    end

    # GET /districts/1/edit
    def edit; end

    # POST /districts or /districts.json
    def create
      @district = District.new(district_params)

      respond_to do |format|
        if @district.save
          format.html { redirect_to admin_district_url(@district), notice: 'District was successfully created.' }
          format.json { render :show, status: :created, location: @district }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @district.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /districts/1 or /districts/1.json
    def update
      respond_to do |format|
        if @district.update(district_params)
          format.html { redirect_to admin_district_url(@district), notice: 'District was successfully updated.' }
          format.json { render :show, status: :ok, location: @district }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @district.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /districts/1 or /districts/1.json
    def destroy
      @district.destroy

      respond_to do |format|
        format.html { redirect_to admin_districts_url, notice: 'District was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    # GET /districts/1/chapters or /districts/1/chapters.json
    def chapters
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_district
      @district = District.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def district_params
      params.fetch(:district, {}).permit(:name, :short_name, :position)
    end
  end
end
