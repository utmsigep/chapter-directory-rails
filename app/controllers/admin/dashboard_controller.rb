# frozen_string_literal: true

module Admin
  # Dashboard Controller
  class DashboardController < ApplicationController
    include Admin::ComparisonPresets

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

      @compare_preset = params[:preset].presence || (params[:compare].blank? ? DEFAULT_PRESET : nil)
      @compare_preset_label = PRESET_LABELS[@compare_preset]
      @comparison_window_label = if @report_date == @compare_date
                                   @report_date.strftime('%-m/%-d/%Y')
                                 else
                                   "#{@report_date.strftime('%-m/%-d/%Y')} vs #{@compare_date.strftime('%-m/%-d/%Y')}"
                                 end
      @preset_shortcuts = preset_shortcuts_for(@report_date)

      refresh_enqueued = false

      # If today's data is missing, enqueue a background refresh so this request stays responsive.
      if @report_date == Date.today && ManpowerSurvey.where(survey_date: @report_date).empty?
        refresh_enqueued = RefreshManpowerSurveyJob.enqueue_for(@report_date)
        flash.now[:notice] = 'Survey refresh queued. Reload in a minute for updated totals.' if refresh_enqueued
      end

      @manpower_survey = [
        { name: 'Chapter Manpower', data: {}, points: false, library: { yAxisID: 'y' } },
        { name: 'Chapters', data: {}, points: false, library: { yAxisID: 'y1' } },
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

        # Chapters
        @manpower_survey[1][:data][survey_date] = count

        # Average Chapter Size
        @manpower_survey[2][:data][survey_date] = average
      end

      if ManpowerSurvey.where(survey_date: @report_date).empty?
        flash.alert = "No survey data available for #{@report_date.strftime('%-m/%-d/%-Y')}"
      end

      has_report_data = ManpowerSurvey.exists?(survey_date: @report_date)
      @latest_survey_date = ManpowerSurvey.maximum(:survey_date)
      @refresh_status = if @report_date != Date.today
                          :historical
                        elsif has_report_data
                          :available
                        elsif refresh_enqueued || RefreshManpowerSurveyJob.queued_for?(@report_date)
                          :queued
                        else
                          :missing
                        end

      @current_manpower = ManpowerSurvey.where(survey_date: @report_date).sum(:manpower)
      @compare_manpower = ManpowerSurvey.where(survey_date: @compare_date).sum(:manpower)
      @manpower_label_date = @report_date
      @net_manpower_change = @current_manpower - @compare_manpower
      @net_manpower_growth_rate = if @compare_manpower.positive?
                                    ((@net_manpower_change.to_f / @compare_manpower) * 100).round(1)
                                  end

      ranking_limit = 25

      largest_scope = ManpowerSurvey.where(survey_date: @report_date)
                .joins(:chapter)
                .where('chapters.status = 1')
                .select('chapters.name, chapters.id, chapters.institution_name, chapters.expansion, manpower_surveys.manpower')
                .order('manpower DESC')
      @largest_chapters = ranked_chapters_with_ties(largest_scope, ranking_limit: ranking_limit, direction: :desc)

      smallest_scope = ManpowerSurvey.where(survey_date: @report_date)
                 .where('manpower_surveys.manpower > 0')
                 .joins(:chapter)
                 .where('chapters.status = 1')
                 .select('chapters.name, chapters.id, chapters.institution_name, chapters.expansion, manpower_surveys.manpower')
                 .order('manpower ASC')
      @smallest_chapters = ranked_chapters_with_ties(smallest_scope, ranking_limit: ranking_limit, direction: :asc)

      @manpower_distribution = ManpowerSurvey.where(survey_date: @report_date)
                                             .joins(:chapter)
                                             .where('chapters.status = 1')
                                             .select('chapters.name, manpower_surveys.manpower, chapters.id')
                                             .order('manpower_surveys.manpower DESC')
                                             .pluck(:name, :manpower, :id, :expansion)

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
      @active_chapter_total = Chapter.active.count
      @reporting_chapters_count = @active_chapters
      @reporting_coverage_rate = if @active_chapter_total.positive?
                                   ((@reporting_chapters_count.to_f / @active_chapter_total) * 100).round(1)
                                 end

      # Fetch manpower surveys for both dates
      surveys_at_report_date = ManpowerSurvey.where(survey_date: @report_date)
      surveys_at_compare_date = ManpowerSurvey.where(survey_date: @compare_date)

      # Create hashes for quick lookup
      report_date_hash = surveys_at_report_date.index_by(&:chapter_id)
      compare_date_hash = surveys_at_compare_date.index_by(&:chapter_id)

      compared_chapter_ids = (report_date_hash.keys + compare_date_hash.keys).uniq
      compared_chapters = Chapter.includes(:district).where(id: compared_chapter_ids).index_by(&:id)

      # Calculate the manpower change for each chapter
      chapter_changes = compared_chapter_ids.map do |chapter_id|
        chapter = compared_chapters[chapter_id]
        next if chapter.nil?

        report_manpower = report_date_hash[chapter.id]&.manpower.to_i
        compare_manpower = compare_date_hash[chapter.id]&.manpower.to_i
        change = report_manpower - compare_manpower
        {
          chapter: chapter,
          manpower_at_report_date: report_manpower,
          manpower_at_compare_date: compare_manpower,
          manpower_change: change
        }
      end.compact
      # Filter out changes with :manpower_change <= 0 and sort in descending order
      chapter_increases = chapter_changes.select { |change| change[:manpower_change].positive? }
                                         .sort_by { |change| change[:manpower_change] }
                                         .reverse
      @chapter_increases = chapter_increases

      # Filter out changes with :manpower_change >= 0 and sort in ascending order
      chapter_decreases = chapter_changes.select { |change| change[:manpower_change].negative? }
                                         .sort_by { |change| change[:manpower_change] }
      @chapter_decreases = chapter_decreases

      @chapters_compared_count = chapter_changes.size
      @chapters_up_count = chapter_increases.size
      @chapters_flat_count = chapter_changes.count { |change| change[:manpower_change].zero? }
      @chapters_down_count = chapter_decreases.size

      @expansion_comparison = build_segment_comparison(
        chapter_changes,
        flag_key: :expansion,
        positive_label: 'Expansion',
        negative_label: 'Non-Expansion'
      )
      @slc_comparison = build_segment_comparison(
        chapter_changes,
        flag_key: :slc,
        positive_label: 'SLC',
        negative_label: 'Non-SLC'
      )

      district_change_stats = Hash.new { |hash, key| hash[key] = { delta: 0, chapters: 0, district_id: nil } }
      chapter_changes.each do |change|
        district_label = district_label_for(change[:chapter].district)
        district_change_stats[district_label][:delta] += change[:manpower_change]
        district_change_stats[district_label][:chapters] += 1
        district_change_stats[district_label][:district_id] ||= change[:chapter].district&.id
      end
      @district_net_change = district_change_stats.transform_values { |stats| stats[:delta] }
                                                  .sort_by { |_, delta| -delta }
                                                  .to_h
      @district_net_change_nonzero = district_change_stats.reject { |_, stats| stats[:delta].zero? }

      district_gains = @district_net_change_nonzero.select { |_, stats| stats[:delta].positive? }
      district_declines = @district_net_change_nonzero.select { |_, stats| stats[:delta].negative? }

      @district_net_gain = district_gains.sort_by { |_, stats| -stats[:delta] }
                                        .first(10)
                                        .to_h
      @district_net_decline = district_declines.sort_by { |_, stats| stats[:delta] }
                                               .first(10)
                                               .to_h
      @district_net_change_table = @district_net_change_nonzero.sort_by { |_, stats| -stats[:delta] }
                                                                .to_h

      @district_net_gain_chart = district_chart_series(@district_net_gain)
      @district_net_gain_links = district_chart_links(@district_net_gain)
      @district_net_decline_chart = district_chart_series(@district_net_decline, absolute: true)
      @district_net_decline_links = district_chart_links(@district_net_decline)
    end

    private

    def ranked_chapters_with_ties(base_scope, ranking_limit:, direction:)
      cutoff = base_scope.offset(ranking_limit - 1).pick(Arel.sql('manpower_surveys.manpower'))
      return base_scope if cutoff.nil?

      case direction
      when :desc
        base_scope.where('manpower_surveys.manpower >= ?', cutoff)
      when :asc
        base_scope.where('manpower_surveys.manpower <= ?', cutoff)
      else
        base_scope
      end
    end

    def district_label_for(district)
      return 'Unassigned' if district.nil?

      short_name = district.short_name.to_s.strip
      return district.name if short_name.blank?
      return short_name if short_name.downcase.include?('district')
      return "District #{short_name}" if short_name.match?(/\A\d+\z/)

      short_name
    end

    def district_chart_series(district_stats, absolute: false)
      district_stats.to_h do |district_name, stats|
        value = absolute ? stats[:delta].abs : stats[:delta]
        [district_name, value]
      end
    end

    def district_chart_links(district_stats)
      district_stats.values.map { |stats| stats[:district_id] ? admin_district_path(stats[:district_id]) : nil }
    end

    def build_segment_comparison(chapter_changes, flag_key:, positive_label:, negative_label:)
      [
        summarize_segment(chapter_changes, flag_key: flag_key, flag_value: true, label: positive_label),
        summarize_segment(chapter_changes, flag_key: flag_key, flag_value: false, label: negative_label)
      ]
    end

    def summarize_segment(chapter_changes, flag_key:, flag_value:, label:)
      segment_changes = chapter_changes.select do |change|
        chapter_flag(change[:chapter], flag_key) == flag_value
      end

      report_total = segment_changes.sum { |change| change[:manpower_at_report_date] }
      compare_total = segment_changes.sum { |change| change[:manpower_at_compare_date] }
      net_change = report_total - compare_total

      {
        label: label,
        chapters: segment_changes.size,
        report_manpower: report_total,
        compare_manpower: compare_total,
        net_change: net_change,
        growth_rate: compare_total.positive? ? ((net_change.to_f / compare_total) * 100).round(1) : nil
      }
    end

    def chapter_flag(chapter, flag_key)
      ActiveModel::Type::Boolean.new.cast(chapter.public_send(flag_key))
    end

  end
end
