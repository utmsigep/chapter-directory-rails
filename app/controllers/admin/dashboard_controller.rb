# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    def index
      @manpower_survey = [
        { name: 'Chapter Manpower', data: {}, points: false  },
        { name: 'Chapter Count', data: {}, format: 'bar', points: false }
      ]
      Chapter.active.each do |c|
        c.manpower_surveys.each do |s|
          survey_date = s.survey_date
          manpower = s.manpower
          @manpower_survey[0]['data'] ||= {}
          @manpower_survey[0]['data'][survey_date] ||= 0
          @manpower_survey[0]['data'][survey_date] += manpower
          @manpower_survey[1]['data'] ||= {}
          @manpower_survey[1]['data'][survey_date] ||= 0
          @manpower_survey[1]['data'][survey_date] += 1
        end
      end

      @active_chapters = Chapter.active.size

      @current_manpower = Chapter.where(status: true).sum(:manpower)

      @largest_chapters = Chapter.where(status: true)
                                 .order('manpower DESC')
                                 .limit(10)

      @smallest_chapters = Chapter.where(status: true)
                                  .where('chapters.manpower > 0')
                                  .order('manpower ASC')
                                  .limit(10)

      @manpower_distribution = Chapter.where(status: true)
                                      .order('manpower DESC')
                                      .pluck(:name, :manpower)
    end
  end
end
