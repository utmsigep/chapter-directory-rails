# frozen_string_literal: true

module ApplicationHelper
  # Map flash notices to bootstrap classes
  def flash_class(level)
    case level
    when :notice then 'alert alert-info'
    when :success then 'alert alert-success'
    when :error then 'alert alert-error'
    when :alert then 'alert alert-error'
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
end
