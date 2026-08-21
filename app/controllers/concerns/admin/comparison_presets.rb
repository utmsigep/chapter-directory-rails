# frozen_string_literal: true

module Admin
  module ComparisonPresets
    extend ActiveSupport::Concern

    PRESET_LABELS = {
      'days_30' => 'Last 30 Days',
      'mom' => 'Month over Month',
      'yoy' => 'Year over Year',
      'prior_pmr' => 'Prior PMR (3/1)'
    }.freeze

    DEFAULT_PRESET = 'days_30'

    private

    def preset_shortcuts_for(report_date)
      PRESET_LABELS.map do |preset_key, label|
        {
          key: preset_key,
          label: label,
          compare_date: compare_date_for_preset(report_date, preset_key)
        }
      end
    end

    def compare_date_for_preset(report_date, preset)
      case preset
      when 'prior_pmr'
        prior_pmr_date(report_date)
      when 'mom'
        report_date << 1
      when 'yoy'
        report_date.prev_year
      when 'days_30'
        report_date - 30
      else
        report_date - 30
      end
    end

    def prior_pmr_date(report_date)
      pmr_this_year = Date.new(report_date.year, 3, 1)
      report_date > pmr_this_year ? pmr_this_year : Date.new(report_date.year - 1, 3, 1)
    end
  end
end
