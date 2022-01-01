class Chapter < ApplicationRecord
    belongs_to :region
    belongs_to :district
    validates_presence_of :name

    include GenerateCsv

    def self.search(query)
        wheres = [
            self.where("name LIKE ?", "%#{query}%"),
            self.where("institution_name LIKE ?", "%#{query}%"),
            self.where("location LIKE ?", "%#{query}%"),
        ]
        wheres.reduce(:or)
    end
end
