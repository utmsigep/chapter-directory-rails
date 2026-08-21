# frozen_string_literal: true

module Admin
  class DistrictsController < ApplicationController
    include Admin::ComparisonPresets

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

      build_district_change_stats
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

    # Compares the district's active chapters' manpower reports on @report_date against @compare_date.
    def build_district_change_stats
      active_chapters = @district.chapters.active.to_a
      @report_date = parse_date(params[:date]) || ManpowerSurvey.where(chapter_id: active_chapters.map(&:id)).maximum(:survey_date)
      return if @report_date.nil?

      @compare_preset = params[:preset].presence || (params[:compare].blank? ? DEFAULT_PRESET : nil)
      @compare_preset_label = PRESET_LABELS[@compare_preset]
      @preset_shortcuts = preset_shortcuts_for(@report_date)
      @compare_date = parse_date(params[:compare]) || compare_date_for_preset(@report_date, @compare_preset || DEFAULT_PRESET)

      chapter_changes = active_chapters.filter_map do |chapter|
        report_manpower = chapter.manpower_surveys.find_by(survey_date: @report_date)&.manpower
        compare_manpower = chapter.manpower_surveys.find_by(survey_date: @compare_date)&.manpower
        next if report_manpower.nil? || compare_manpower.nil?

        { chapter: chapter, report_manpower: report_manpower, compare_manpower: compare_manpower,
          change: report_manpower - compare_manpower }
      end

      @report_manpower = chapter_changes.sum { |c| c[:report_manpower] }
      @compare_manpower = chapter_changes.sum { |c| c[:compare_manpower] }
      @manpower_net_change = @report_manpower - @compare_manpower
      @manpower_growth_rate = ((@manpower_net_change.to_f / @compare_manpower) * 100).round(1) if @compare_manpower.positive?

      @chapters_up_count = chapter_changes.count { |c| c[:change].positive? }
      @chapters_flat_count = chapter_changes.count { |c| c[:change].zero? }
      @chapters_down_count = chapter_changes.count { |c| c[:change].negative? }

      @chapter_movers = chapter_changes.sort_by { |c| -c[:change].abs }
    end

    def parse_date(value)
      Date.parse(value) if value.present?
    rescue ArgumentError, TypeError
      nil
    end

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
