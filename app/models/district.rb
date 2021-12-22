class District < ApplicationRecord
    has_many :chapters
    validates_presence_of :name, :short_name
end
