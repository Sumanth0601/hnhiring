class TelegramNotifier
  API_URL = "https://api.telegram.org/bot%s/sendMessage"

  def initialize
    @token   = ENV.fetch('TELEGRAM_BOT_TOKEN')
    @chat_id = ENV.fetch('TELEGRAM_CHAT_ID')
  end

  def send_job(comment)
    title = extract_title(comment.description)
    hn_url = "https://news.ycombinator.com/item?id=#{comment.api_id}"

    plain_desc = comment.description.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ')
    tag = if plain_desc.match?(/\bpython\b/i)
            '🐍 *New Remote Python Job on HN*'
          elsif plain_desc.match?(/\bSDE\b|\bSWE\b/i)
            '💼 *New Remote SDE\/SWE Job on HN*'
          else
            '💻 *New Remote Software Job on HN*'
          end

    text = <<~MSG
      #{tag}

      #{escape(title)}

      👤 #{escape(comment.username)}
      🔗 #{hn_url}
    MSG

    send_message(text)
  end

  def send_message(text)
    conn = Faraday.new(url: format(API_URL, @token))
    response = conn.post do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = { chat_id: @chat_id, text: text, parse_mode: 'Markdown' }.to_json
    end

    unless response.success?
      raise "Telegram API error: #{response.status} — #{response.body}"
    end

    response
  end

  private

  def extract_title(html)
    # First line of the post, stripped of HTML tags, truncated to 200 chars
    plain = html.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
    plain.split(/\s*[\|\-–—•]\s*|\n/).first.to_s.strip.slice(0, 200)
  end

  def escape(text)
    text.to_s.gsub(/[_*\[\]()~`>#+\-=|{}.!]/, '\\\\\0')
  end
end
