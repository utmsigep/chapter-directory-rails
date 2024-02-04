# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :region, optional: true
  belongs_to :district, optional: true
  has_many :manpower_surveys
  validates_presence_of :name

  scope :active, -> { where(status: 1) }
  scope :inactive, -> { where(status: 0) }

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
