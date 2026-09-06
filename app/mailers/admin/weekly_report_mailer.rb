# frozen_string_literal: true

module Admin
  # Sends the weekly Sunday-morning summary of the admin dashboard.
  class WeeklyReportMailer < ApplicationMailer
    def weekly_summary(recipients:, report_date: Date.today, compare_date: report_date - 7)
      @report_date = report_date
      @compare_date = compare_date
      @report = Admin::DashboardReport.new(report_date: @report_date, compare_date: @compare_date, compare_preset: nil)

      mail(
        to: recipients,
        subject: "Chapter Directory Weekly Report - #{@report_date.strftime('%-m/%-d/%Y')}"
      )
    end
  end
end
