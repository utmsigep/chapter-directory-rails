class Chapter < ApplicationRecord
    belongs_to :region
    belongs_to :district
    validates_presence_of :name
end
