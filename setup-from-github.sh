#!/bin/bash

echo "🌐 Starting full setup from GitHub..."

read -p "📦 GitHub repo URL (public or with token): " GITHUB_REPO_URL

REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)

# Check if directory already exists
if [ -d "$REPO_NAME" ]; then
  echo "📁 Repo already exists. Pulling latest changes..."
  cd "$REPO_NAME"
  git pull
  cd ..
else
  echo "📥 Cloning repo..."
  git clone "$GITHUB_REPO_URL"
fi

read -p "🌍 Enter your DOMAIN (e.g., mysite.com): " DOMAIN
read -p "🌐 Enter your SUBDOMAIN (e.g., www.mysite.com): " SUBDOMAIN
read -p "🔢 Enter your AWS ACCOUNT ID: " ACCOUNT_ID

# Auto-set values in setup script if present
if [ -f "$REPO_NAME/cloudfront_static_site_setup.sh" ]; then
  sed -i "s|^DOMAIN=.*|DOMAIN=\"$DOMAIN\"|" "$REPO_NAME/cloudfront_static_site_setup.sh"
  sed -i "s|^SUBDOMAIN=.*|SUBDOMAIN=\"$SUBDOMAIN\"|" "$REPO_NAME/cloudfront_static_site_setup.sh"
  sed -i "s|^ACCOUNT_ID=.*|ACCOUNT_ID=\"$ACCOUNT_ID\"|" "$REPO_NAME/cloudfront_static_site_setup.sh"
else
  echo "⚠️ cloudfront_static_site_setup.sh not found — skipping sed updates"
fi

read -p "🤖 Enter your Telegram BOT_TOKEN: " BOT_TOKEN
read -p "👤 Enter your Telegram CHAT_ID: " CHAT_ID

# Replace placeholders in bot script
if [ -f "$REPO_NAME/telegram_deploy_bot.py" ]; then
  sed -i "s|BOT_TOKEN = .*|BOT_TOKEN = \"$BOT_TOKEN\"|" "$REPO_NAME/telegram_deploy_bot.py"
  sed -i "s|CHAT_ID = .*|CHAT_ID = \"$CHAT_ID\"|" "$REPO_NAME/telegram_deploy_bot.py"

  echo "📲 Starting Telegram bot in background (tmux session 'deploybot')..."
  cd "$REPO_NAME"
  tmux new-session -d -s deploybot "python3 telegram_deploy_bot.py"
  cd ..
else
  echo "⚠️ telegram_deploy_bot.py not found — skipping bot launch"
fi

read -p "🚀 Do you want to deploy your site now? (y/n): " deploy_now
if [ "$deploy_now" == "y" ] && [ -f "$REPO_NAME/cloudfront_static_site_setup.sh" ]; then
  cd "$REPO_NAME"
  chmod +x cloudfront_static_site_setup.sh
  ./cloudfront_static_site_setup.sh
  cd ..
fi

echo ""
echo "✅ Setup complete!"
echo "📱 Use Telegram commands: /start /deploy /lock /unlock /update_phone /status /logs"
echo "🧠 Don't forget to update your domain registrar with the Route 53 nameservers!"
