# frozen_string_literal: true

class Region < ApplicationRecord
  has_many :chapters
  validates_presence_of :name, :short_name

  include GenerateCsv
end
