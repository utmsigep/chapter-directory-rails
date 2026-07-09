require "test_helper"

class RefreshManpowerSurveyJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @previous_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    clear_enqueued_jobs
    clear_performed_jobs
  end

  teardown do
    Rails.cache = @previous_cache
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "enqueue_for dedupes jobs by survey date" do
    survey_date = Date.new(2026, 7, 8)

    assert RefreshManpowerSurveyJob.enqueue_for(survey_date)
    assert RefreshManpowerSurveyJob.queued_for?(survey_date)
    assert_not RefreshManpowerSurveyJob.enqueue_for(survey_date)
    assert_enqueued_jobs 1, only: RefreshManpowerSurveyJob
  end

  test "clear enqueue marker removes queued status" do
    survey_date = Date.new(2026, 7, 8)

    RefreshManpowerSurveyJob.enqueue_for(survey_date)
    assert RefreshManpowerSurveyJob.queued_for?(survey_date)

    RefreshManpowerSurveyJob.clear_enqueue_marker(survey_date)
    assert_not RefreshManpowerSurveyJob.queued_for?(survey_date)
  end

  test "perform clears enqueue marker for historical run" do
    survey_date = Date.today - 1

    RefreshManpowerSurveyJob.enqueue_for(survey_date)
    assert RefreshManpowerSurveyJob.queued_for?(survey_date)

    perform_enqueued_jobs do
      RefreshManpowerSurveyJob.perform_later(survey_date)
    end

    assert_not RefreshManpowerSurveyJob.queued_for?(survey_date)
  end
end
