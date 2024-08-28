# frozen_string_literal: true

require 'rake'

module Admin
  # Dashboard Controller
  class DashboardController < ApplicationController
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

      # If @report_date is Date.today and there are no entries for ManpowerSurvey,
      # kick off the `chapter:update_info` rake task.
      if @report_date == Date.today && ManpowerSurvey.where(survey_date: @report_date).empty?
        Rake::Task.clear
        ChapterDirectory::Application.load_tasks
        Rake::Task['chapter:update_info'].reenable
        Rake::Task['chapter:update_info'].invoke
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

      @smallest_chapters = ManpowerSurvey.where(survey_date: @report_date)
                                         .where('manpower_surveys.manpower > 0')
                                         .joins(:chapter)
                                         .select('chapters.name, chapters.id, chapters.institution_name, manpower_surveys.manpower')
                                         .order('manpower ASC')

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
                               sorted_values[size / 2] if sorted_values.size.positive?
                             elsif sorted_values.size.positive?
                               (sorted_values[(size / 2) - 1] + sorted_values[size / 2]) / 2.0
                             end

      @active_chapters = values.size

      # Fetch manpower surveys for both dates
      surveys_at_report_date = ManpowerSurvey.where(survey_date: @report_date)
      surveys_at_compare_date = ManpowerSurvey.where(survey_date: @compare_date)

      # Create hashes for quick lookup
      report_date_hash = surveys_at_report_date.index_by(&:chapter_id)
      compare_date_hash = surveys_at_compare_date.index_by(&:chapter_id)

      # Calculate the manpower change for each chapter
      chapter_changes = Chapter.all.map do |chapter|
        report_manpower = report_date_hash[chapter.id]&.manpower.to_i
        compare_manpower = compare_date_hash[chapter.id]&.manpower.to_i
        change = report_manpower - compare_manpower
        {
          chapter: chapter,
          manpower_at_report_date: report_manpower,
          manpower_at_compare_date: compare_manpower,
          manpower_change: change
        }
      end
      @chapter_increases = chapter_changes.sort_by { |change| change[:manpower_change] }.reverse!
      @chapter_decreases = chapter_changes.sort_by { |change| change[:manpower_change] }
    end
  end
end
