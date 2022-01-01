require 'csv'
require 'net/http'

namespace :app do
  desc "Update chapters without latitude/longitude from Wikipedia"
  task :geocode_chapters, [:path] => [:environment] do |t, args|
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
end
