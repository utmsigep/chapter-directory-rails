json.extract! chapter, :name, :slc, :website, :institution_name, :location, :latitude, :longitude, :manpower
json.region chapter.region, partial: "map/region", as: :region
json.district chapter.district, partial: "map/district", as: :district
