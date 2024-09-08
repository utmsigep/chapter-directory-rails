# frozen_string_literal: true

module ApplicationHelper
  # Map flash notices to bootstrap classes
  def flash_class(level)
    case level
    when 'notice' then 'alert alert-info'
    when 'success' then 'alert alert-success'
    when 'error' then 'alert alert-danger'
    when 'alert' then 'alert alert-warning'
    else 'alert alert-info'
    end
  end

  def full_title(page_title = '')
    base_title = 'Chapter Directory'
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  def role_check(role)
    current_user&.send("#{role}?")
  end

  def us_states
    [
      ['Alabama', 'Alabama'],
      ['Alaska', 'Alaska'],
      ['Arizona', 'Arizona'],
      ['Arkansas', 'Arkansas'],
      ['California', 'California'],
      ['Colorado', 'Colorado'],
      ['Connecticut', 'Connecticut'],
      ['Delaware', 'Delaware'],
      ['District of Columbia', 'District of Columbia'],
      ['Florida', 'Florida'],
      ['Georgia', 'Georgia'],
      ['Hawaii', 'Hawaii'],
      ['Idaho', 'Idaho'],
      ['Illinois', 'Illinois'],
      ['Indiana', 'Indiana'],
      ['Iowa', 'Iowa'],
      ['Kansas', 'Kansas'],
      ['Kentucky', 'Kentucky'],
      ['Louisiana', 'Louisiana'],
      ['Maine', 'Maine'],
      ['Maryland', 'Maryland'],
      ['Massachusetts', 'Massachusetts'],
      ['Michigan', 'Michigan'],
      ['Minnesota', 'Minnesota'],
      ['Mississippi', 'Mississippi'],
      ['Missouri', 'Missouri'],
      ['Montana', 'Montana'],
      ['Nebraska', 'Nebraska'],
      ['Nevada', 'Nevada'],
      ['New Hampshire', 'New Hampshire'],
      ['New Jersey', 'New Jersey'],
      ['New Mexico', 'New Mexico'],
      ['New York', 'New York'],
      ['North Carolina', 'North Carolina'],
      ['North Dakota', 'North Dakota'],
      ['Ohio', 'Ohio'],
      ['Oklahoma', 'Oklahoma'],
      ['Oregon', 'Oregon'],
      ['Pennsylvania', 'Pennsylvania'],
      ['Puerto Rico', 'Puerto Rico'],
      ['Rhode Island', 'Rhode Island'],
      ['South Carolina', 'South Carolina'],
      ['South Dakota', 'South Dakota'],
      ['Tennessee', 'Tennessee'],
      ['Texas', 'Texas'],
      ['Utah', 'Utah'],
      ['Vermont', 'Vermont'],
      ['Virginia', 'Virginia'],
      ['Washington', 'Washington'],
      ['West Virginia', 'West Virginia'],
      ['Wisconsin', 'Wisconsin'],
      ['Wyoming', 'Wyoming'],
    ]
  end

end
