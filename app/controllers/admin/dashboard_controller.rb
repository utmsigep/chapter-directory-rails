# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    def index
      begin
        @report_date = Date.today
        @report_date = Date.parse(params[:date]) unless params[:date].nil? || params[:date].empty?
        raise 'Cannot be later than today' if @report_date > Date.today
      rescue StandardError => e
        # Add a flash message that an invalid date was provided
        flash.alert = "Error: #{e.message}"
        @report_date = Date.today
      end

      begin
        @compare_date = Date.today - 30
        @compare_date = Date.parse(params[:compare]) unless params[:compare].nil? || params[:compare].empty?
        raise 'Cannot be later than the report date' if @compare_date > @report_date
        raise 'Cannot be later than today' if @compare_date > Date.today
      rescue StandardError => e
        # Add a flash message that an invalid date was provided
        flash.alert = "Error: #{e.message}"
        @compare_date = Date.today - 30
      end

      @manpower_survey = [
        { name: 'Chapter Manpower', data: {}, points: false, library: { yAxisID: 'y' } },
        { name: 'Chapter Count', data: {}, points: false, library: { yAxisID: 'y1' } },
        { name: 'Average Chapter Size', data: {}, points: false, library: { yAxisID: 'y1' } }
      ]

      # Query to get aggregated data from ManpowerSurvey
      aggregated_data = ManpowerSurvey
                        .where('survey_date <= ?', @report_date)
                        .group(:survey_date)
                        .pluck(:survey_date, Arel.sql('SUM(manpower) AS sum'), Arel.sql('CEIL(AVG(manpower)) AS average'), Arel.sql('COUNT(*) AS count'))

      # Process the aggregated data
      aggregated_data.each do |survey_date, sum, average, count|
        survey_date = survey_date.strftime('%Y-%m-%d')

        # Chapter Manpower
        @manpower_survey[0][:data][survey_date] = sum

        # Chapter Count
        @manpower_survey[1][:data][survey_date] = count

        # Average Chapter Size
        @manpower_survey[2][:data][survey_date] = average
      end

      if ManpowerSurvey.where(survey_date: @report_date).size === 0
        flash.alert = "No survey data available for #{@report_date.strftime('%-m/%-d/%-Y')}"
      end

      @current_manpower = ManpowerSurvey.where(survey_date: @report_date).sum(:manpower)
      @compare_manpower = ManpowerSurvey.where(survey_date: @compare_date).sum(:manpower)

      @largest_chapters = ManpowerSurvey.where(survey_date: @report_date)
                                        .joins(:chapter)
                                        .select('chapters.name, chapters.id, chapters.institution_name, manpower_surveys.manpower')
                                        .order('manpower DESC')
                                        .limit(10)

      @smallest_chapters = ManpowerSurvey.where(survey_date: @report_date)
                                         .where('manpower_surveys.manpower > 0')
                                         .joins(:chapter)
                                         .select('chapters.name, chapters.id, chapters.institution_name, manpower_surveys.manpower')
                                         .order('manpower ASC')
                                         .limit(10)

      @manpower_distribution = ManpowerSurvey.where(survey_date: @report_date)
                                             .joins(:chapter)
                                             .select('chapters.name, manpower_surveys.manpower, chapters.id')
                                             .order('manpower_surveys.manpower DESC')
                                             .pluck(:name, :manpower, :id)

      values = @manpower_distribution.map { |_, manpower| manpower }
      @average_chapter_size = values.sum / values.size.to_f

      sorted_values = values.sort
      size = sorted_values.size
      @median_chapter_size = if size.odd?
                               sorted_values[size / 2] if sorted_values.size > 0
                             else
                               (sorted_values[(size / 2) - 1] + sorted_values[size / 2]) / 2.0 if sorted_values.size > 0
                             end

      @active_chapters = values.size
    end
  end
end
