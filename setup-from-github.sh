#!/bin/bash

echo "🌐 Starting full setup from GitHub..."

# Load env vars from config file
CONFIG_FILE="./deploy-config.env"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Config file $CONFIG_FILE not found!"
  exit 1
fi
echo "📄 Loading configuration from $CONFIG_FILE"
source "$CONFIG_FILE"

# Clone or pull script repo
REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)
if [ -d "$REPO_NAME" ]; then
  echo "📁 Repo already exists. Pulling latest changes..."
  cd "$REPO_NAME"
  git pull
  cd ..
else
  echo "📥 Cloning repo..."
  git clone "$GITHUB_REPO_URL"
fi

# Inject domain settings into deploy script
if [ -f "$REPO_NAME/cloudfront_static_site_setup.sh" ]; then
  sed -i "s|^DOMAIN=.*|DOMAIN=\"$DOMAIN\"|" "$REPO_NAME/cloudfront_static_site_setup.sh"
  sed -i "s|^SUBDOMAIN=.*|SUBDOMAIN=\"$SUBDOMAIN\"|" "$REPO_NAME/cloudfront_static_site_setup.sh"
  sed -i "s|^ACCOUNT_ID=.*|ACCOUNT_ID=\"$ACCOUNT_ID\"|" "$REPO_NAME/cloudfront_static_site_setup.sh"
fi

# Replace bot credentials
if [ -f "$REPO_NAME/telegram_deploy_bot.py" ]; then
  sed -i "s|BOT_TOKEN = .*|BOT_TOKEN = \"$BOT_TOKEN\"|" "$REPO_NAME/telegram_deploy_bot.py"
  sed -i "s|CHAT_ID = .*|CHAT_ID = \"$CHAT_ID\"|" "$REPO_NAME/telegram_deploy_bot.py"
  echo "📲 Starting Telegram bot in background (tmux session 'deploybot')..."
  cd "$REPO_NAME"
  tmux new-session -d -s deploybot "python3 telegram_deploy_bot.py"
  cd ..
fi

# Auto-run site deploy using static site repo
if [ -f "$REPO_NAME/cloudfront_static_site_setup.sh" ]; then
  echo "🚀 Deploying static site using: $SITE_REPO"
  export DOMAIN SUBDOMAIN ACCOUNT_ID GITHUB_REPO_URL="$SITE_REPO"
  cd "$REPO_NAME"
  chmod +x cloudfront_static_site_setup.sh
  ./cloudfront_static_site_setup.sh
  cd ..
else
  echo "⚠️ No cloudfront_static_site_setup.sh found in $REPO_NAME"
fi

echo ""
echo "✅ Setup complete!"
echo "📱 Use Telegram commands: /start /deploy /lock /unlock /update_phone /status /logs"
echo "🧠 Don't forget to update your domain registrar with the Route 53 nameservers!"



echo "DOMAIN: $DOMAIN"
echo "SUBDOMAIN: $SUBDOMAIN"
echo "ACCOUNT_ID: $ACCOUNT_ID"
echo "BOT_TOKEN: $BOT_TOKEN"
echo "CHAT_ID: $CHAT_ID"
echo "SITE_REPO: $SITE_REPO"
