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

      @largest_chapters = Chapter.joins(:manpower_surveys)
                                 .select('
                                   chapters.*, MAX(manpower_surveys.survey_date) as latest_survey_date,
                                   MAX(manpower_surveys.manpower) as latest_manpower
                                 ')
                                 .where('chapters.status = 1')
                                 .group('chapters.id')
                                 .order('latest_manpower DESC')
                                 .limit(10)

      @smallest_chapters = Chapter.joins(:manpower_surveys)
                                  .select('
                                    chapters.*, MAX(manpower_surveys.survey_date) as latest_survey_date,
                                    MAX(manpower_surveys.manpower) as latest_manpower
                                  ')
                                  .where('chapters.status = 1')
                                  .where('chapters.manpower > 0')
                                  .group('chapters.id')
                                  .order('latest_manpower ASC')
                                  .limit(10)
    end
  end
end
