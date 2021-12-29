require 'csv'
require 'net/http'

namespace :app do
  desc "Import chapters from specified CSV file"
  task :import_chapters, [:path] => [:environment] do |t, args|
    path = args[:path]
    if path.nil?
      puts "Usage: rake 'app:import_chapters[/Users/username/Downloads/chapters.csv]'"
      exit 1
    end
    unless File.exists?(path)
      puts "No file found at: #{path}"
      exit 1
    end
    begin
      csv = CSV.read(path, headers: true)
    rescue CSV::MalformedCSVError => error
      puts "[ERROR] #{error}"
      exit 1
    end

    # Create Regions if Missing
    csv.each do |row|
      region = Region.find_or_create_by(short_name: row['region'])
      region.name = "Region #{row['region']}" if region.name.nil?
      region.short_name = "#{row['region']}" if region.short_name.nil?
      region.position = row['region'].to_i if region.position == 0
      region.save!

      district = District.find_or_create_by(short_name: row['district'])
      district.name = "District #{row['district']}" if district.name.nil?
      district.short_name = "#{row['district']}" if district.short_name.nil?
      district.position = row['district'].to_i if district.position == 0
      district.save!
    end

    # Process Chapter Updates
    csv.each do |row|
      chapter = Chapter.find_or_create_by(name: row['name'])
      chapter.name = row['name']
      chapter.slc = row['slc']
      chapter.institution_name = row['institution_name']
      chapter.location = row['location']
      chapter.latitude = row['latitude']
      chapter.longitude = row['longitude']
      chapter.district = District.find_by(short_name: row['district'])
      chapter.region = Region.find_by(short_name: row['region'])
      chapter.save!
    end
  end

  desc "Export chapters to a CSV file"
  task :export_chapters, [:path] => [:environment] do |t, args|
    path = args[:path]
    if path.nil?
      puts "Usage: rake 'app:export_chapters[/Users/username/Downloads/chapters.csv]'"
      exit 1
    end

    CSV.open(path, 'wb') do |csv|
      csv << 'name,slc,institution_name,location,latitude,longitude,region,district'.parse_csv
      Chapter.all.each do |chapter|
        csv << [chapter.name, chapter.slc, chapter.institution_name, chapter.location, chapter.latitude, chapter.longitude, chapter.region.short_name, chapter.district.short_name]
      end
    end
  end

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
