# frozen_string_literal: true

require 'csv'

module GenerateCsv
  extend ActiveSupport::Concern

  class_methods do
    def generate_csv
      CSV.generate(headers: true) do |csv|
        csv << attribute_names

        all.each do |record|
          csv << record.attributes.values
        end
      end
    end
  end
end
