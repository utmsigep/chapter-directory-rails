json.extract! chapter, :name, :slc, :status, :website, :institution_name, :location, :latitude, :longitude, :manpower
json.district chapter.district, partial: 'map/district', as: :district
