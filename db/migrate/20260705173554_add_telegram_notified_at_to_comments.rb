class AddTelegramNotifiedAtToComments < ActiveRecord::Migration[6.1]
  def change
    add_column :comments, :telegram_notified_at, :datetime
  end
end
