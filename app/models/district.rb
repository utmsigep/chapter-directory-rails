# frozen_string_literal: true

class District < ApplicationRecord
  has_many :chapters
  validates_presence_of :name, :short_name

  include GenerateCsv
  has_many :chapters
end
