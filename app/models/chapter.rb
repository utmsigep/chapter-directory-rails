# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :district, optional: true
  has_many :manpower_surveys
  validates_presence_of :name

  before_save :normalize_field

  scope :active, -> { where(status: 1) }
  scope :inactive, -> { where(status: 0) }

  include GenerateCsv

  def normalize_field
    return unless institution_name.present?

    institution_name.gsub!(' Of ', ' of ')
    institution_name.gsub!(' At ', ' at ')
    institution_name.gsub!(' And ', ' and ')
  end

  def self.search(query, include_inactive = false)
    wheres = [
      where('name LIKE ?', "%#{query}%"),
      where('institution_name LIKE ?', "%#{query}%"),
      where('location LIKE ?', "%#{query}%")
    ]

    return wheres.reduce(:or) if include_inactive

    wheres.reduce(:or).where('status = ?', 1)
  end
end
