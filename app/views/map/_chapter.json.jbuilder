json.extract! chapter, :name, :slc, :website, :institution_name, :location, :latitude, :longitude, :manpower
json.district chapter.district, partial: "map/district", as: :district
