# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :district, optional: true
  validates_presence_of :name

  include GenerateCsv

  def institution_name=(val)
    self[:institution_name] = val.gsub(' Of ', ' of ')
  end

  def self.search(query)
    wheres = [
      where('name LIKE ?', "%#{query}%"),
      where('institution_name LIKE ?', "%#{query}%"),
      where('location LIKE ?', "%#{query}%")
    ]
    wheres.reduce(:or).where('status = ?', 1)
  end
end
