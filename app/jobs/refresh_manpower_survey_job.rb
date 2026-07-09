# frozen_string_literal: true

require 'rake'

class RefreshManpowerSurveyJob < ApplicationJob
  queue_as :default

  ENQUEUE_TTL = 5.minutes

  def self.cache_key_for(survey_date)
    "jobs/refresh_manpower_survey/#{survey_date.iso8601}"
  end

  def self.queued_for?(survey_date)
    Rails.cache.exist?(cache_key_for(survey_date))
  end

  def self.clear_enqueue_marker(survey_date)
    Rails.cache.delete(cache_key_for(survey_date))
  end

  def self.enqueue_for(survey_date)
    cache_key = cache_key_for(survey_date)
    return false if Rails.cache.read(cache_key)

    Rails.cache.write(cache_key, true, expires_in: ENQUEUE_TTL)
    perform_later(survey_date)
    true
  end

  def perform(survey_date)
    report_date = Date.parse(survey_date.to_s)
    return unless report_date == Date.today
    return if ManpowerSurvey.exists?(survey_date: report_date)

    Rake::Task.clear
    ChapterDirectory::Application.load_tasks
    Rake::Task['chapter:update_info'].reenable
    Rake::Task['chapter:update_info'].invoke
  ensure
    self.class.clear_enqueue_marker(report_date) if defined?(report_date) && report_date
  end
end
