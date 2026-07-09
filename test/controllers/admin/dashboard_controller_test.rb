require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:admin)
  end

  test "should get index" do
    get admin_url
    assert_response :success
  end

  test "increase and decrease rankings include all changing chapters" do
    report_date = Date.new(2026, 7, 8)
    compare_date = Date.new(2026, 6, 8)

    30.times do |index|
      chapter = Chapter.create!(
        name: "Increase Chapter #{index + 1}",
        institution_name: "Increase University #{index + 1}",
        status: true
      )
      ManpowerSurvey.create!(chapter: chapter, survey_date: compare_date, manpower: 100)
      ManpowerSurvey.create!(chapter: chapter, survey_date: report_date, manpower: 101 + index)
    end

    30.times do |index|
      chapter = Chapter.create!(
        name: "Decrease Chapter #{index + 1}",
        institution_name: "Decrease University #{index + 1}",
        status: true
      )
      ManpowerSurvey.create!(chapter: chapter, survey_date: compare_date, manpower: 101 + index)
      ManpowerSurvey.create!(chapter: chapter, survey_date: report_date, manpower: 100)
    end

    get admin_url(date: report_date, compare: compare_date)

    assert_response :success
    assert_includes response.body, "Increase Chapter 1"
    assert_includes response.body, "Decrease Chapter 1"
  end

  test "largest ranking includes ties at cutoff" do
    report_date = Date.new(2026, 7, 8)

    26.times do |index|
      chapter = Chapter.create!(
        name: "Tie Largest #{index + 1}",
        institution_name: "Tie University #{index + 1}",
        status: true
      )
      ManpowerSurvey.create!(chapter: chapter, survey_date: report_date, manpower: 200)
    end

    get admin_url(date: report_date, compare: report_date)

    assert_response :success
    assert_includes response.body, "Tie Largest 26"
  end

  test "district section includes chapter counts and reporting coverage" do
    report_date = Date.new(2026, 7, 8)
    compare_date = Date.new(2026, 6, 8)

    chapter = Chapter.create!(
      name: "Coverage Chapter",
      institution_name: "Coverage University",
      status: true
    )
    ManpowerSurvey.create!(chapter: chapter, survey_date: compare_date, manpower: 80)
    ManpowerSurvey.create!(chapter: chapter, survey_date: report_date, manpower: 90)

    get admin_url(date: report_date, compare: compare_date)

    assert_response :success
    assert_includes response.body, "Reporting Coverage"
    assert_match(/\(\d+ ch\)/, response.body)
    assert_includes response.body, "District Net Change Snapshot"
    assert_includes response.body, "Chapters"
  end

  test "renders quick preset chips and selected preset label" do
    report_date = Date.new(2026, 7, 8)
    compare_date = Date.new(2025, 7, 8)

    get admin_url(date: report_date, compare: compare_date, preset: 'yoy')

    assert_response :success
    assert_includes response.body, "Year over Year"
    assert_includes response.body, "Month over Month"
    assert_includes response.body, "Last 30 Days"
    assert_match(/class=\"btn btn-sm btn-primary\"[^>]*preset=yoy[^>]*>Year over Year</, response.body)
  end

  test "renders segment comparisons for expansion and slc groups" do
    report_date = Date.new(2026, 7, 8)
    compare_date = Date.new(2026, 6, 8)

    chapter_expansion_slc = Chapter.create!(
      name: "Expansion SLC",
      institution_name: "Expansion U",
      status: true,
      expansion: true,
      slc: true
    )
    chapter_non_expansion_non_slc = Chapter.create!(
      name: "Non Expansion Non SLC",
      institution_name: "Non Expansion U",
      status: true,
      expansion: false,
      slc: false
    )

    ManpowerSurvey.create!(chapter: chapter_expansion_slc, survey_date: compare_date, manpower: 40)
    ManpowerSurvey.create!(chapter: chapter_expansion_slc, survey_date: report_date, manpower: 50)
    ManpowerSurvey.create!(chapter: chapter_non_expansion_non_slc, survey_date: compare_date, manpower: 60)
    ManpowerSurvey.create!(chapter: chapter_non_expansion_non_slc, survey_date: report_date, manpower: 55)

    get admin_url(date: report_date, compare: compare_date)

    assert_response :success
    assert_includes response.body, "Expansion vs Non-Expansion"
    assert_includes response.body, "SLC vs Non-SLC"
    assert_includes response.body, "Window: 7/8/2026 vs 6/8/2026"
    assert_includes response.body, "Expansion"
    assert_includes response.body, "Non-Expansion"
    assert_includes response.body, "Non-SLC"
  end

  test "shows queued refresh status when survey refresh is enqueued" do
    report_date = Date.today
    compare_date = report_date - 30

    get admin_url(date: report_date, compare: compare_date)

    assert_response :success
    assert_includes response.body, "Refresh queued"
    assert_includes response.body, "Survey refresh queued. Reload in a minute for updated totals."
  end
end
