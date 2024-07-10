# frozen_string_literal: true

require 'csv'
require 'net/http'
require 'logger'

logger = Logger.new($stdout)
logger.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO

namespace :chapter do
  desc 'Update chapters without latitude/longitude from Wikipedia'
  task geocode: :environment do
    chapters = Chapter.where(latitude: nil, longitude: nil)
    chapters.each do |chapter|
      geocoded_by = 'institution'
      begin
        url = URI.parse("https://en.wikipedia.org/w/api.php?action=query&titles=#{CGI.escape(chapter.institution_name)}&prop=coordinates&redirects&format=json")
        logger.debug url
        response = Net::HTTP.get_response(url)
        logger.debug response.body
        json = JSON.parse(response.body)
      rescue StandardError => e
        logger.warn "Failed retrieving data for #{chapter.name} (#{chapter.institution_name})"
        logger.warn e.message
        next
      end
      k, wiki = json['query']['pages'].first
      # Try the location name if the institution page doesn't work
      if k == '-1' || wiki['coordinates'].nil?
        geocoded_by = 'location'
        begin
          url = URI.parse("https://en.wikipedia.org/w/api.php?action=query&titles=#{chapter.location}&prop=coordinates&redirects&format=json")
          logger.debug(url)
          response = Net::HTTP.get_response(url)
          logger.debug(response.body)
          json = JSON.parse(response.body)
        rescue StandardError => e
          logger.warn "Failed retrieving data for #{chapter.name} (#{chapter.institution_name})"
          logger.warn e.message
          next
        end
        unless json['query']
          logger.warn "Unable to find coordinates for #{chapter.name} (#{chapter.institution_name})"
          next
        end
        k, wiki = json['query']['pages'].first
        if k == '-1' || wiki['coordinates'].nil?
          logger.warn "Unable to find coordinates for #{chapter.name} (#{chapter.institution_name})"
          next
        end
      end
      chapter.latitude = wiki['coordinates'].first['lat']
      chapter.longitude = wiki['coordinates'].first['lon']
      logger.info("Updating #{chapter.name} (#{chapter.institution_name}) with #{chapter.latitude}, #{chapter.longitude} - #{geocoded_by}")
      chapter.save!
    end
  end

  desc 'Check active chapters'
  task check_active: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first')
    logger.debug url
    response = Net::HTTP.get_response(url)
    logger.debug response.body
    json_list = JSON.parse(response.body)
    # Removes the "N/A" records
    json_list = json_list.delete_if { |c| c['chapterdesignation'].empty? }

    # Guard against data issues
    if json_list.empty?
      logger.error '[Error] Chapter list is empty.'
      logger.error "```\n#{response.body}\n```"
      exit(1)
    end

    all_chapters = Chapter.all
    active_chapters = Chapter.where('status = ?', 1)
    inactive_chapters = Chapter.where('status = ?', 0)

    exit_code = 0
    output = { not_in_db: [], inactive_now_active: [], no_longer_active: [] }

    json_list.each do |chapter|
      output[:not_in_db] << chapter['chapterdesignation'] unless all_chapters.any? do |db|
                                                                   db['name'] == chapter['chapterdesignation']
                                                                 end
    end

    inactive_chapters.each do |chapter|
      next unless json_list.any? { |js| js['chapterdesignation'] == chapter['name'] }

      output[:inactive_now_active] << chapter['name']
      chapter.status = true
      chapter.save!
    end

    active_chapters.each do |chapter|
      next if json_list.any? { |js| js['chapterdesignation'] == chapter['name'] }

      output[:no_longer_active] << chapter['name']
      chapter.status = false
      chapter.save!
    end

    unless output[:not_in_db].empty?
      logger.error ''
      logger.error 'Chapters not appearing in the database:'
      logger.error '======================================='
      logger.error output[:not_in_db].join("\n")
      logger.error ''
      exit_code = 1
    end

    unless output[:inactive_now_active].empty?
      logger.error ''
      logger.error 'Previously inactive chapters now active:'
      logger.error '========================================'
      logger.error output[:inactive_now_active].join("\n")
      logger.error ''
      exit_code = 1
    end

    unless output[:no_longer_active].empty?
      logger.error ''
      logger.error 'Chapters no longer appearing on the active list:'
      logger.error '================================================'
      logger.error output[:no_longer_active].join("\n")
      logger.error ''
      exit_code = 1
    end

    exit(exit_code)
  end

  desc 'Update SLC status'
  task update_slc: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first')
    logger.debug url
    response = Net::HTTP.get_response(url)
    logger.debug response.body
    slc_chapters = JSON.parse(response.body)
    # Removes the "N/A" records
    slc_chapters = slc_chapters.delete_if { |c| c['chapterdesignation'].empty? }

    all_chapters = Chapter.all

    all_chapters.each do |chapter|
      chapter.slc = if slc_chapters.any? do |h|
                         h['chapterdesignation'] == chapter['name'] && h['slcstatus'].match(/SLC/i)
                       end
                      1
                    else
                      0
                    end
      chapter.save!
    end
  end

  desc 'Update District Alignment'
  task update_districts: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=19285&target_action=get-all-data&default_sorting=old_first')
    logger.debug url
    response = Net::HTTP.get_response(url)
    logger.debug response.code
    logger.debug response.body
    districts = JSON.parse(response.body)

    # Null out all values
    # Skip this step for now. Usually not needed.
    # Chapter.all.update_all(district_id: nil)

    districts.each do |record|
      district = District.find_by(name: record['district'])
      if district.nil?
        district = District.new
        district.name = record['district']
        district.short_name = record['district'].gsub('District ', '')
        district.position = record['district'].gsub('District ', '') if record['district'].match?(/^District \d+$/)
      end
      district.staff_name = record['name']
      district.save!

      chapters = record['activechapters'].split(', ')
      chapters.each do |chapter_record|
        chapter = Chapter.find_by(name: chapter_record)
        if chapter.nil?
          logger.warn "[WARNING] Chapter #{chapter} not found!"
          next
        end
        chapter.district = district
        chapter.save!
      end
    end

    orphaned_chapters = Chapter.where(district: nil, status: 1)
    unless orphaned_chapters.empty?
      logger.warn '[WARNING] The following chapters do not have a district assigned:'
      orphaned_chapters.each do |chapter|
        logger.warn "- #{chapter['name']} - #{chapter['institution_name']}"
      end
    end
  end

  desc 'Update chapter information'
  task update_info: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first')
    logger.debug url
    response = Net::HTTP.get_response(url)
    logger.debug response.code
    logger.debug response.body
    json_list = JSON.parse(response.body)
    # Removes the "N/A" records
    json_list = json_list.delete_if { |c| c['chapterdesignation'].empty? }

    json_list.each do |chapter_record|
      chapter = Chapter.find_by(name: chapter_record['chapterdesignation'])
      if chapter.nil?
        chapter = Chapter.new
        chapter.name = chapter_record['chapterdesignation']
        chapter.status = true
      end
      chapter.manpower = chapter_record['currentchaptersize'] ? chapter_record['currentchaptersize'].to_i : 0
      chapter.location = "#{chapter_record['city']}, #{chapter_record['state']}"
      chapter.institution_name = chapter_record['dyadinstitutionalid']
      chapter.website = chapter_record['website']
      chapter.save!

      # Daily survey of manpower
      manpower_survey = ManpowerSurvey.find_or_initialize_by(chapter: chapter, survey_date: Date.today)
      manpower_survey.chapter = chapter
      manpower_survey.survey_date = Date.today
      manpower_survey.manpower = chapter.manpower
      manpower_survey.save!

    end

    # Unsets manpower for orphaned chapters
    Chapter.where('status = ?', 0).update_all(manpower: 0)
  end
end
