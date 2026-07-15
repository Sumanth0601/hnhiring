namespace :telegram do
  desc "Import latest HN jobs and notify via Telegram for new remote Python/FastAPI/Flask/Django jobs"
  task notify_python_remote: :environment do
    puts "[#{Time.current}] Starting telegram:notify_python_remote"

    # Step 1: Refresh data (same as rake cron)
    puts "Importing latest posts..."
    ImportMonthService.new.call

    puts "Populating keywords..."
    Keyword.populate!

    # Step 2: Find unsent remote+relevant jobs from the current hiring post
    python_comment_ids = Comment.joins(:keywords)
                                .merge(Keyword.technology.where(slug: 'python'))
                                .select(:id)

    remote_comment_ids = Comment.joins(:keywords)
                                .merge(Keyword.location.where(slug: 'remote'))
                                .select(:id)

    role_keyword_ids = Comment.where(
                                "description ILIKE ? OR description ILIKE ? OR description ILIKE ? OR description ILIKE ?",
                                '%SDE%', '%SWE%', '%Software%', '%Founding%'
                              ).select(:id)

    matching_ids = Comment.where(id: python_comment_ids).or(Comment.where(id: role_keyword_ids))
                          .select(:id)

    jobs = Comment.where(id: matching_ids)
                  .where(id: remote_comment_ids)
                  .where(telegram_notified_at: nil)
                  .joins(:post)
                  .merge(Post.where(type: 'HiringPost'))
                  .order(published_at: :asc)

    puts "Found #{jobs.count} new remote job(s) to notify."

    notifier = TelegramNotifier.new
    sent = 0
    failed = 0

    jobs.each do |comment|
      begin
        notifier.send_job(comment)
        comment.update_column(:telegram_notified_at, Time.current)
        puts "  ✓ Notified: comment ##{comment.api_id} by #{comment.username}"
        sent += 1
      rescue => e
        puts "  ✗ Failed for comment ##{comment.api_id}: #{e.message}"
        failed += 1
      end
    end

    puts "[#{Time.current}] Done. Sent: #{sent}, Failed: #{failed}"

    # Write status file so the UI can show last run info
    status = {
      last_run_at: Time.current.iso8601,
      jobs_sent:   sent,
      jobs_failed: failed
    }
    File.write(Rails.root.join('tmp', 'telegram_status.json'), status.to_json)
  end
end
