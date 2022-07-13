# frozen_string_literal: true

require 'csv'
require 'net/http'

namespace :chapter do
  desc 'Update chapters without latitude/longitude from Wikipedia'
  task geocode: :environment do
    chapters = Chapter.where(latitude: nil, longitude: nil)
    chapters.each do |chapter|
      geocoded_by = 'institution'
      begin
        url = URI.parse("https://en.wikipedia.org/w/api.php?action=query&titles=#{chapter.institution_name}&prop=coordinates&redirects&format=json")
        response = Net::HTTP.get_response(url)
        json = JSON.parse(response.body)
      rescue StandardError => e
        puts "Failed retrieving data for #{chapter.name} (#{chapter.institution_name})"
        puts e.message
        next
      end
      k, wiki = json['query']['pages'].first
      # Try the location name if the institution page doesn't work
      if k == '-1' || wiki['coordinates'].nil?
        geocoded_by = 'location'
        begin
          url = URI.parse("https://en.wikipedia.org/w/api.php?action=query&titles=#{chapter.location}&prop=coordinates&redirects&format=json")
          response = Net::HTTP.get_response(url)
          json = JSON.parse(response.body)
        rescue StandardError => e
          puts "Failed retrieving data for #{chapter.name} (#{chapter.institution_name})"
          puts e.message
          next
        end
        k, wiki = json['query']['pages'].first
        if k == '-1' || wiki['coordinates'].nil?
          puts "Unable to find coordinates for #{chapter.name} (#{chapter.institution_name})"
          next
        end
      end
      chapter.latitude = wiki['coordinates'].first['lat']
      chapter.longitude = wiki['coordinates'].first['lon']
      puts "Updating #{chapter.name} (#{chapter.institution_name}) with #{chapter.latitude}, #{chapter.longitude} - #{geocoded_by}"
      chapter.save!
    end
  end

  desc 'Check active chapters'
  task check_active: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first')
    response = Net::HTTP.get_response(url)
    json_list = JSON.parse(response.body)
    # Removes the "N/A" records
    json_list = json_list.delete_if { |c| c['chapterdesignation'].empty? }

    all_chapters = Chapter.all
    active_chapters = Chapter.where('status = ?', 1)
    inactive_chapters = Chapter.where('status = ?', 0)

    puts ''
    puts 'Chapters not appearing in the database:'
    puts '======================================='
    json_list.each do |chapter|
      puts chapter['chapterdesignation'] unless all_chapters.any? { |db| db['name'] == chapter['chapterdesignation'] }
    end

    puts ''
    puts 'Previously inactive chapters now active:'
    puts '========================================'
    inactive_chapters.each do |chapter|
      next unless json_list.any? { |js| js['chapterdesignation'] == chapter['name'] }

      puts chapter['name']
      chapter.status = true
      chapter.save!
    end

    puts ''
    puts 'Chapters no longer appearing on the active list:'
    puts '================================================'
    active_chapters.each do |chapter|
      next if json_list.any? { |js| js['chapterdesignation'] == chapter['name'] }

      puts chapter['name']
      chapter.status = false
      chapter.save!
    end

    puts ''
  end

  desc 'Update SLC status'
  task update_slc: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first')
    response = Net::HTTP.get_response(url)
    slc_chapters = JSON.parse(response.body)
    # Removes the "N/A" records
    slc_chapters = slc_chapters.delete_if { |c| c['chapterdesignation'].empty? }

    all_chapters = Chapter.all

    all_chapters.each do |chapter|
      if slc_chapters.any? { |h| h['chapterdesignation'] == chapter['name'] && h['slcstatus'].match(/SLC/i) }
        chapter.slc = 1
      else
        chapter.slc = 0
      end
      chapter.save!
    end
  end

  desc 'Update Region Alignment'
  task update_regions: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=20940&target_action=get-all-data&default_sorting=old_first')
    response = Net::HTTP.get_response(url)
    regions = JSON.parse(response.body)

    # Null out all values
    Chapter.all.update_all(region_id: nil)

    regions.each do |record|
      region = Region.find_by(name: record['region'])
      if region.nil?
        region = Region.new
        region.name = record['region']
        region.short_name = record['lookup']
        region.position = record['lookup'] if record['lookup'].match?(/^\d+$/)
        region.save!
      end

      chapters = record['chaptersinregion'].split(', ')
      chapters.each do |chapter_record|
        chapter = Chapter.find_by(name: chapter_record)
        if chapter.nil?
          puts "[WARNING] Chapter #{chapter} not found!"
          next
        end
        chapter.region = region
        chapter.save!
      end
    end

    orphaned_chapters = Chapter.where(region: nil, status: 1)
    unless orphaned_chapters.empty?
      puts '[WARNING] The following chapters do not have a region assigned:'
      orphaned_chapters.each do |chapter|
        puts "- #{chapter['name']} - #{chapter['institution_name']}"
      end
    end
  end

  desc 'Update District Alignment'
  task update_districts: :environment do
    url = URI.parse('https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=19285&target_action=get-all-data&default_sorting=old_first')
    response = Net::HTTP.get_response(url)
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
        district.save!
      end

      chapters = record['activechapters'].split(', ')
      chapters.each do |chapter_record|
        chapter = Chapter.find_by(name: chapter_record)
        if chapter.nil?
          puts "[WARNING] Chapter #{chapter} not found!"
          next
        end
        chapter.district = district
        chapter.save!
      end
    end

    orphaned_chapters = Chapter.where(district: nil, status: 1)
    unless orphaned_chapters.empty?
      puts '[WARNING] The following chapters do not have a district assigned:'
      orphaned_chapters.each do |chapter|
        puts "- #{chapter['name']} - #{chapter['institution_name']}"
      end
    end
  end
end
