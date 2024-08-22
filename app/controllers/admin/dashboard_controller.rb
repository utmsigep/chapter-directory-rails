# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    def index
      @manpower_survey = [
        { name: 'Chapter Manpower', data: {}, points: false, library: { yAxisID: 'y' } },
        { name: 'Chapter Count', data: {}, points: false, library: { yAxisID: 'y1' } },
        { name: 'Average Chapter Size', data: {}, points: false, library: { yAxisID: 'y1' } }
      ]
      Chapter.active.each do |c|
        c.manpower_surveys.each do |s|
          survey_date = s.survey_date
          manpower = s.manpower

          # Chapter Manpower
          @manpower_survey[0]['data'] ||= {}
          @manpower_survey[0]['data'][survey_date] ||= 0
          @manpower_survey[0]['data'][survey_date] += manpower

          # Chapter Count
          @manpower_survey[1]['data'] ||= {}
          @manpower_survey[1]['data'][survey_date] ||= 0
          @manpower_survey[1]['data'][survey_date] += 1

          # Average Chapter Size
          @manpower_survey[2]['data'] ||= {}
          @manpower_survey[2]['data'][survey_date] ||= 0
          @manpower_survey[2]['data'][survey_date] = @manpower_survey[0]['data'][survey_date] / @manpower_survey[1]['data'][survey_date]
        end
      end

      @current_manpower = ManpowerSurvey.where(survey_date: Date.today).sum(:manpower)
      @previous_month_manpower = ManpowerSurvey.where(survey_date: Date.today.last_month).sum(:manpower)
      @previous_quarter_manpower = ManpowerSurvey.where(survey_date: Date.today.last_quarter).sum(:manpower)

      @largest_chapters = Chapter.active
                                 .order('manpower DESC')
                                 .limit(10)

      @smallest_chapters = Chapter.active
                                  .where('chapters.manpower > 0')
                                  .order('manpower ASC')
                                  .limit(10)

      @manpower_distribution = Chapter.active
                                      .order('manpower DESC')
                                      .pluck(:name, :manpower, :id)

      # Add click action to each @manpower_distribution to navigate to the chapter :id
      @manpower_distribution.each do |chapter|
        # generate a link to the admin/chapters/:id route
        chapter[2] = admin_chapter_path(chapter[2])
      end

      values = @manpower_distribution.map { |_, manpower| manpower }
      @average_chapter_size = values.sum / values.size.to_f

      sorted_values = values.sort
      size = sorted_values.size
      @median_chapter_size = if size.odd?
                               sorted_values[size / 2]
                             else
                               (sorted_values[(size / 2) - 1] + sorted_values[size / 2]) / 2.0
                             end

      @active_chapters = Chapter.active.size
    end
  end
end
