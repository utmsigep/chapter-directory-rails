json.extract! chapter, :name, :slc, :website, :institution_name, :location, :latitude, :longitude, :manpower
json.url admin_chapter_url(chapter, format: :json)
json.district chapter.district, partial: "admin/districts/district", as: :district
