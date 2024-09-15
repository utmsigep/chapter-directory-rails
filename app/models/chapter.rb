# frozen_string_literal: true

class Chapter < ApplicationRecord
  belongs_to :district, optional: true
  has_many :manpower_surveys
  validates_presence_of :name

  before_save :normalize_field

  default_scope { order(chapter_roll: :asc) }
  scope :active, -> { where(status: 1) }
  scope :inactive, -> { where(status: 0) }

  # Define state abbreviations
  STATE_ABBREVIATIONS = {
    'Alabama' => 'AL',
    'Alaska' => 'AK',
    'Arizona' => 'AZ',
    'Arkansas' => 'AR',
    'California' => 'CA',
    'Colorado' => 'CO',
    'Connecticut' => 'CT',
    'District of Columbia' => 'DC',
    'Delaware' => 'DE',
    'Florida' => 'FL',
    'Georgia' => 'GA',
    'Hawaii' => 'HI',
    'Idaho' => 'ID',
    'Illinois' => 'IL',
    'Indiana' => 'IN',
    'Iowa' => 'IA',
    'Kansas' => 'KS',
    'Kentucky' => 'KY',
    'Louisiana' => 'LA',
    'Maine' => 'ME',
    'Maryland' => 'MD',
    'Massachusetts' => 'MA',
    'Michigan' => 'MI',
    'Minnesota' => 'MN',
    'Mississippi' => 'MS',
    'Missouri' => 'MO',
    'Montana' => 'MT',
    'Nebraska' => 'NE',
    'Nevada' => 'NV',
    'New Hampshire' => 'NH',
    'New Jersey' => 'NJ',
    'New Mexico' => 'NM',
    'New York' => 'NY',
    'North Carolina' => 'NC',
    'North Dakota' => 'ND',
    'Ohio' => 'OH',
    'Oklahoma' => 'OK',
    'Oregon' => 'OR',
    'Pennsylvania' => 'PA',
    'Rhode Island' => 'RI',
    'South Carolina' => 'SC',
    'South Dakota' => 'SD',
    'Tennessee' => 'TN',
    'Texas' => 'TX',
    'Utah' => 'UT',
    'Vermont' => 'VT',
    'Virginia' => 'VA',
    'Washington' => 'WA',
    'West Virginia' => 'WV',
    'Wisconsin' => 'WI',
    'Wyoming' => 'WY'
  }.freeze

  # Define Greek letters
  GREEK_LETTERS = {
    'Alpha' => '&#913;',
    'Beta' => '&#914;',
    'Gamma' => '&#915;',
    'Delta' => '&#916;',
    'Epsilon' => '&#917;',
    'Zeta' => '&#918;',
    'Eta' => '&#919;',
    'Theta' => '&#920;',
    'Iota' => '&#921;',
    'Kappa' => '&#922;',
    'Lambda' => '&#923;',
    'Mu' => '&#924;',
    'Nu' => '&#925;',
    'Xi' => '&#926;',
    'Omicron' => '&#927;',
    'Pi' => '&#928;',
    'Rho' => '&#929;',
    'Sigma' => '&#931;',
    'Tau' => '&#932;',
    'Upsilon' => '&#933;',
    'Phi' => '&#934;',
    'Chi' => '&#935;',
    'Psi' => '&#936;',
    'Omega' => '&#937;'
  }.freeze

  def normalize_field
    return unless institution_name.present?

    institution_name.gsub!(' Of ', ' of ')
    institution_name.gsub!(' At ', ' at ')
    institution_name.gsub!(' And ', ' and ')
  end

  def location
    [city, state].compact.join(', ')
  end

  # Abbreviate Chapter Name
  def abbreviation
    # Shorten the state name
    abbreviated_state = STATE_ABBREVIATIONS[state] || state

    # Extract the Greek letter part from the name
    name_parts = name.gsub('D.C.', 'District of Columbia').gsub(state, abbreviated_state).split
    greek_part = name_parts[1..].join(' ') # Assuming Greek part is after the state part

    # Convert Greek letters
    greek_letters = greek_part.split.map { |letter| GREEK_LETTERS[letter] || letter }.join(' ')

    # Combine the abbreviated state with converted Greek letters
    "#{abbreviated_state} #{greek_letters}"
  end

  def self.as_csv(chapters)
    CSV.generate do |csv|
      unless chapters
        csv << column_names
        all.each do |item|
          csv << item.attributes.values
        end
      else
        csv << [
          'Roll #',
          'Chapter',
          'Institution Name',
          'Status',
          'SLC?',
          'Expansion?',
          'City',
          'State',
          'Latitude',
          'Longitude',
          'Charter Date',
          'Manpower',
          'District',
          'Website'
        ]
        chapters.each do |item|
          csv << [
            item.chapter_roll,
            item.name,
            item.institution_name,
            item.status ? 'Active' : 'Dormant',
            item.slc ? 'Yes' : 'No',
            item.expansion ? 'Yes' : 'No',
            item.city,
            item.state,
            item.latitude,
            item.longitude,
            item.charter_date,
            item.manpower,
            item.district&.short_name,
            item.website
          ]
        end
      end
    end
  end

  # Class method to generate Wikimedia-compatible table
  def self.to_wikimedia_table(chapters)
    # Helper to format the institution name into a Wikipedia page link
    def self.wikipedia_link(name)
      return '' if name.nil? || name.empty?

      # Format the name to create a valid Wikipedia page link
      formatted_name = name.strip.gsub(/\s+/, '_') # Replace spaces with underscores
      "[[#{formatted_name}|#{name}]]"
    end

    # Helper to format dates in a Wikipedia-friendly format using the {{dts}} template
    def self.dts_date(date)
      return 'N/A' if date.nil?
      date.strftime('{{dts|%Y|%m|%d}}') # Format: {{dts|YYYY|MM|DD}} (e.g., {{dts|2024|09|14}})
    end

    # Helper to determine the row style based on status
    def self.row_style(status)
      status ? 'background-color: #9EFF9E;' : 'background-color: #FFC7C7;'
    end

    # Table header with sortable columns
    table_header = <<~HEADER
      {| class="wikitable sortable"
      ! Roll #
      ! Chapter
      ! Abbreviation
      ! Chartered/Range
      ! Institution
      ! City
      ! State
      ! Status
      ! References
    HEADER

    # Table rows with updated column data, status text, and row styles
    table_rows = all.map do |chapter|
      chartered_range = dts_date(chapter.charter_date)
      status_text = chapter.status ? 'Active' : 'Dormant'
      institution_link = wikipedia_link(chapter.institution_name)
      row_style = row_style(chapter.status)

      <<~ROW
        |- style="#{row_style}"
        | #{chapter.chapter_roll || 'N/A'}
        | #{chapter.name || 'N/A'}
        | #{chapter.abbreviation}
        | #{chartered_range}
        | #{institution_link}
        | #{chapter.city || 'N/A'}
        | #{chapter.state || 'N/A'}
        | #{status_text}
        |
      ROW
    end.join("\n")

    # Table footer
    table_footer = "\n|}"

    # Combine everything into the final table format
    [table_header, table_rows, table_footer].join("\n")
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
