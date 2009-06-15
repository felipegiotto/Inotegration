# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def format_date(date)
    date.strftime "%Y-%m-%d %H:%M:%S"
  end

  def pre_text(text)
    '<pre>' + h(text).gsub(%r{([^\s\n\r]{100})}, "\\1\n") + '</pre>'
  end
end
