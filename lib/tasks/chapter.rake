require 'csv'
require 'net/http'

namespace :chapter do
  desc "Update chapters without latitude/longitude from Wikipedia"
  task :geocode, [:path] => [:environment] do |t, args|
    chapters = Chapter.where(latitude: nil, longitude: nil)
    chapters.each do |chapter|
      geocoded_by = 'institution'
      begin
        url = URI.parse("https://en.wikipedia.org/w/api.php?action=query&titles=#{chapter.institution_name}&prop=coordinates&redirects&format=json")
        response = Net::HTTP.get_response(url)
        json = JSON.parse(response.body)
      rescue => e
        puts "Failed retrieving data for #{chapter.name} (#{chapter.institution_name})"
        puts e.message
        next
      end
      _k, wiki = json['query']['pages'].first
      # Try the location name if the institution page doesn't work
      if _k === '-1' || wiki['coordinates'].nil?
        geocoded_by = 'location'
        begin
          url = URI.parse("https://en.wikipedia.org/w/api.php?action=query&titles=#{chapter.location}&prop=coordinates&redirects&format=json")
          response = Net::HTTP.get_response(url)
          json = JSON.parse(response.body)
        rescue => e
          puts "Failed retrieving data for #{chapter.name} (#{chapter.institution_name})"
          puts e.message
          next
        end
        _k, wiki = json['query']['pages'].first
        if _k === '-1' || wiki['coordinates'].nil?
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

  desc "Check active chapters"
  task :check_active, [:path] => [:environment] do |t, args|
    url = URI.parse("https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first")
    response = Net::HTTP.get_response(url)
    active_chapters = JSON.parse(response.body)
    # Removes the "N/A" records
    active_chapters = active_chapters.delete_if { |c| c['chapterdesignation'].empty? }

    all_chapters = Chapter.where('status', 1)

    puts ""
    puts "Chapters not currently in the database:"
    puts "======================================="
    active_chapters.each do |chapter|
      puts "#{chapter['chapterdesignation']}" unless all_chapters.any? { |h| h['name'] == chapter['chapterdesignation'] }
    end

    puts ""
    puts "Chapters no longer appearing on the active list:"
    puts "================================================"
    all_chapters.each do |chapter|
      puts "#{chapter['name']}" unless active_chapters.any? { |h| h['chapterdesignation'] == chapter['name'] }
    end

    puts ""
  end

  desc "Update SLC status"
  task :update_slc, [:path] => [:environment] do |t, args|
    url = URI.parse("https://sigep.org/wp-admin/admin-ajax.php?action=wp_ajax_ninja_tables_public_action&table_id=18473&target_action=get-all-data&default_sorting=old_first")
    response = Net::HTTP.get_response(url)
    slc_chapters = JSON.parse(response.body)
    # Removes the "N/A" records
    slc_chapters = slc_chapters.delete_if { |c| c['chapterdesignation'].empty? }

    all_chapters = Chapter.all

    all_chapters.each do |chapter|
      if slc_chapters.any? { |h| h['chapterdesignation'] == chapter['name'] and h['slcstatus'].match(/SLC/i) }
        chapter.slc = 1
      else
        chapter.slc = 0
      end
      chapter.save!
    end
  end
end
