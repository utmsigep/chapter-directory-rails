# frozen_string_literal: true

namespace :report do
  desc 'Send the weekly admin dashboard summary email (Sundays only, unless FORCE=1)'
  task weekly_summary: :environment do
    unless Date.today.sunday? || ENV['FORCE'] == '1'
      puts 'Skipping: today is not Sunday (set FORCE=1 to send anyway).'
      next
    end

    recipients = ENV['EMAIL_REPORT_RECIPIENTS'].to_s.split(',').map(&:strip).reject(&:blank?)
    if recipients.empty?
      warn 'EMAIL_REPORT_RECIPIENTS is not set; no report sent.'
      next
    end

    Admin::WeeklyReportMailer.weekly_summary(recipients: recipients).deliver_now
    puts "Weekly report sent to #{recipients.join(', ')}"
  end
end
