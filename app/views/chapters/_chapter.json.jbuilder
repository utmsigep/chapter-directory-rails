json.extract! chapter, :name, :slc, :website, :institution_name, :location, :latitude, :longitude
json.url chapter_url(chapter, format: :json)
json.region chapter.region, partial: "regions/region", as: :region
json.district chapter.district, partial: "districts/district", as: :district