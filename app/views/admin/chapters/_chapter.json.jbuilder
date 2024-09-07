json.extract! chapter, :name, :status, :slc, :website, :institution_name, :location, :latitude, :longitude, :manpower, :expansion, :chapter_roll, :charter_date
json.url admin_chapter_url(chapter, format: :json)
json.district chapter.district, partial: "admin/districts/district", as: :district
