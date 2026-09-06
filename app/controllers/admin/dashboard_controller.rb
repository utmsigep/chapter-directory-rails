# frozen_string_literal: true

module Admin
  # Dashboard Controller
  class DashboardController < ApplicationController
    include Admin::ComparisonPresets

    def index
      begin
        @report_date = Date.today
        @report_date = Date.parse(params[:date]) unless params[:date].nil? || params[:date].empty?
        raise 'Cannot be later than today' if @report_date > Date.today
      rescue StandardError => e
        # Add a flash message that an invalid date was provided
        return redirect_to admin_path, flash: { error: "[Error] #{e.message}" }
      end

      begin
        @compare_date = Date.today - 30
        @compare_date = Date.parse(params[:compare]) unless params[:compare].nil? || params[:compare].empty?
        raise 'Cannot be later than the report date' if @compare_date > @report_date
        raise 'Cannot be later than today' if @compare_date > Date.today
      rescue StandardError => e
        # Add a flash message that an invalid date was provided
        return redirect_to admin_path, flash: { error: "[Error] #{e.message}" }
      end

      @compare_preset = params[:preset].presence || (params[:compare].blank? ? DEFAULT_PRESET : nil)

      refresh_enqueued = false

      # If today's data is missing, enqueue a background refresh so this request stays responsive.
      if @report_date == Date.today && ManpowerSurvey.where(survey_date: @report_date).empty?
        refresh_enqueued = RefreshManpowerSurveyJob.enqueue_for(@report_date)
        flash.now[:notice] = 'Survey refresh queued. Reload in a minute for updated totals.' if refresh_enqueued
      end

      flash.alert = "No survey data available for #{@report_date.strftime('%-m/%-d/%-Y')}" if ManpowerSurvey.where(survey_date: @report_date).empty?

      has_report_data = ManpowerSurvey.exists?(survey_date: @report_date)
      @refresh_status = if @report_date != Date.today
                          :historical
                        elsif has_report_data
                          :available
                        elsif refresh_enqueued || RefreshManpowerSurveyJob.queued_for?(@report_date)
                          :queued
                        else
                          :missing
                        end

      report = Admin::DashboardReport.new(report_date: @report_date, compare_date: @compare_date, compare_preset: @compare_preset)
      assign_report_ivars(report)
    end

    private

    def assign_report_ivars(report)
      %i[
        compare_preset_label comparison_window_label preset_shortcuts manpower_survey latest_survey_date
        current_manpower compare_manpower manpower_label_date net_manpower_change net_manpower_growth_rate
        largest_chapters smallest_chapters manpower_distribution average_chapter_size median_chapter_size
        active_chapters active_chapter_total reporting_chapters_count reporting_coverage_rate chapter_increases
        chapter_decreases chapters_compared_count chapters_up_count chapters_flat_count chapters_down_count
        expansion_comparison slc_comparison district_net_change district_net_change_nonzero district_net_gain
        district_net_decline district_net_change_table district_net_gain_chart district_net_decline_chart
        zero_manpower_chapters
      ].each do |attribute|
        instance_variable_set("@#{attribute}", report.public_send(attribute))
      end

      @district_net_gain_links = report.district_net_gain_links.map { |district_id| district_id ? admin_district_path(district_id) : nil }
      @district_net_decline_links = report.district_net_decline_links.map { |district_id| district_id ? admin_district_path(district_id) : nil }
    end
  end
end
