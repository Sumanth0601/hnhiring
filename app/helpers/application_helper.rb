module ApplicationHelper
  def telegram_notifier_status
    path = Rails.root.join('tmp', 'telegram_status.json')
    return nil unless File.exist?(path)
    JSON.parse(File.read(path), symbolize_names: true)
  rescue JSON::ParserError
    nil
  end

  def default_title
    "All Jobs From Hacker News 'Who is Hiring?' Posts"
  end

  def job_timestamp(timestamp)
    timestamp < 24.hours.ago ? timestamp.to_date : "#{time_ago_in_words(timestamp)} ago"
  end

  def external_link(title, url)
    link_to(title, url, target: '_blank', rel: 'noopener noreferrer')
  end
end
