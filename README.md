# HN Hiring

HN Hiring is an index of jobs from Hacker News' Who is Hiring? posts.

It also includes an automated Telegram notification system that alerts you every
15 minutes about new remote job postings that mention Python/FastAPI/Flask/Django
or contain the terms SDE, SWE, or Software (case-insensitive).

## Requirements

* [Mise](https://mise.jdx.dev/)
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) (for Postgres)
* [Homebrew](https://brew.sh/) (macOS)

---

## 1. Install mise

```bash
curl https://mise.run | sh
echo 'eval "$($HOME/.local/bin/mise activate zsh)"' >> ~/.zshrc
source ~/.zshrc
```

## 2. Install libpq (needed to compile the pg gem)

```bash
brew install libpq
```

## 3. Start Postgres via Docker

```bash
docker compose up -d
```

If you need to override the default port (5432):

```bash
cp .mise.local.sample .mise.local.toml
# edit .mise.local.toml and set DB_PORT = 5433 (or your preferred port)
```

## 4. Install Ruby, Node, and gems

```bash
mise settings ruby.compile=false   # use precompiled Ruby binary
mise install
bundle config set --local build.pg "--with-pg-config=/opt/homebrew/opt/libpq/bin/pg_config"
bundle install
```

## 5. Set up the database

```bash
bundle exec rake db:create db:migrate
```

## 6. Load jobs

```bash
bundle exec rake cron
```

## 7. Run the server

```bash
bundle exec rails s
```

Visit [localhost:3000](http://localhost:3000)

---

## Telegram Notifications (Remote Jobs)

Sends a Telegram message for every new remote job that mentions Python, FastAPI,
Flask, Django, SDE, SWE, or Software (all case-insensitive). Runs every 15
minutes via macOS launchd — survives restarts and catches up after sleep.

### Step 1 — Create a Telegram bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot` and follow the prompts → you'll receive a **BOT_TOKEN**
3. Start a chat with your new bot, then visit:
   ```
   https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
   Find `"chat":{"id":...}` in the response — that is your **CHAT_ID**

### Step 2 — Add credentials to .env

Create a `.env` file in the project root (it is gitignored):

```bash
TELEGRAM_BOT_TOKEN=your_bot_token_here
TELEGRAM_CHAT_ID=your_chat_id_here
```

### Step 3 — Install the launchd agent

This schedules the notifier to run every 15 minutes, auto-starts on login,
and handles starting Docker + Postgres automatically if they are not running.

```bash
# 1. Clone or copy the project to ~/Developer (NOT Downloads — macOS restricts launchd there)
git clone git@github.com:Sumanth0601/hnhiring.git ~/Developer/hnhiring
cd ~/Developer/hnhiring

# 2. Make the wrapper script executable
chmod +x bin/telegram_notify.sh

# 3. Update the username in the plist if it is not 'sumanth'
# sed -i '' 's/sumanth/YOUR_USERNAME/g' config/launchd/com.hnhiring.telegram_notify.plist

# 4. Copy the plist to your LaunchAgents folder
cp config/launchd/com.hnhiring.telegram_notify.plist \
   ~/Library/LaunchAgents/com.hnhiring.telegram_notify.plist

# 5. Load it
launchctl load ~/Library/LaunchAgents/com.hnhiring.telegram_notify.plist

# 6. Verify it is running
launchctl list | grep hnhiring
```

To unload / stop it:

```bash
launchctl unload ~/Library/LaunchAgents/com.hnhiring.telegram_notify.plist
```

### What the notifier does on each run

1. Starts Docker Desktop if it is not already running
2. Starts the postgres container if it is not already running
3. Imports the latest HN hiring thread
4. Tags comments with keywords (python, flask, fastapi, django, remote, etc.)
5. Finds jobs tagged with both `python` **and** `remote` that have not been sent yet
6. Sends one Telegram message per job with the title, author, and HN link
7. Marks each sent job with `telegram_notified_at` so it is never sent again

### Logs

```bash
tail -f log/telegram_notify.log
```

### Running manually

```bash
bundle exec rake telegram:notify_python_remote
```
