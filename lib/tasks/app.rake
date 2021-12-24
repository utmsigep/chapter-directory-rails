require 'csv'

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
      region.name = "#{row['region']}" if region.short_name.nil?
      region.save!

      district = District.find_or_create_by(short_name: row['district'])
      district.name = "District #{row['district']}" if district.name.nil?
      district.name = "#{row['district']}" if district.short_name.nil?
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

end
