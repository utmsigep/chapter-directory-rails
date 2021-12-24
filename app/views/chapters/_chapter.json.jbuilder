json.extract! chapter, :name, :short_name, :institution_name, :institution_short_name, :latitude, :longitude
json.url chapter_url(chapter, format: :json)
json.region chapter.region, partial: "regions/region", as: :region
json.district chapter.district, partial: "districts/district", as: :district