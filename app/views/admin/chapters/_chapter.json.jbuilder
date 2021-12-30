json.extract! chapter, :name, :slc, :website, :institution_name, :location, :latitude, :longitude
json.url admin_chapter_url(chapter, format: :json)
json.region chapter.region, partial: "admin/regions/region", as: :region
json.district chapter.district, partial: "admin/districts/district", as: :district