#!/bin/bash

# === UNIVERSAL CLOUDFRONT STATIC SITE SETUP + TELEGRAM BOT (From GitHub) ===

echo "🌐 Starting full setup from GitHub..."

# Step 1: Ask for GitHub repo (with token if private)
read -p "📦 GitHub repo URL (public or with token): " GITHUB_REPO_URL

# Extract repo name
REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)

# Clone repo
echo "📥 Cloning repo..."
git clone "$GITHUB_REPO_URL"
cd "$REPO_NAME" || { echo "❌ Failed to cd into repo"; exit 1; }

# Step 2: Ask for domain, subdomain, account ID
read -p "🌍 Enter your DOMAIN (e.g., mysite.com): " DOMAIN
read -p "🌐 Enter your SUBDOMAIN (e.g., www.mysite.com): " SUBDOMAIN
read -p "🔢 Enter your AWS ACCOUNT ID: " ACCOUNT_ID

# Inject values into setup script
sed -i "s|^DOMAIN=.*|DOMAIN=\"$DOMAIN\"|" cloudfront_static_site_setup.sh
sed -i "s|^SUBDOMAIN=.*|SUBDOMAIN=\"$SUBDOMAIN\"|" cloudfront_static_site_setup.sh
sed -i "s|^ACCOUNT_ID=.*|ACCOUNT_ID=\"$ACCOUNT_ID\"|" cloudfront_static_site_setup.sh

# Step 3: Make scripts executable
chmod +x *.sh
mkdir -p /home/cloudshell-user/logs
touch /home/cloudshell-user/logs/actions.log

# Step 4: Telegram bot config
read -p "🤖 Enter your Telegram BOT_TOKEN: " BOT_TOKEN
read -p "👤 Enter your Telegram CHAT_ID: " CHAT_ID

# Inject into Python script
sed -i "s|BOT_TOKEN = .*|BOT_TOKEN = \"$BOT_TOKEN\"|" telegram_deploy_bot.py
sed -i "s|CHAT_ID = .*|CHAT_ID = \"$CHAT_ID\"|" telegram_deploy_bot.py

# Step 5: Start bot in background
echo "📲 Starting Telegram bot in background (tmux session 'deploybot')..."
tmux new -d -s deploybot "cd ~/$REPO_NAME && python3 telegram_deploy_bot.py"

# Step 6: Ask to deploy now
read -p "🚀 Do you want to deploy your site now? (y/n): " deploy_now
if [[ "$deploy_now" == "y" ]]; then
  ./cloudfront_static_site_setup.sh
fi

# Step 7: Show reminder
echo ""
echo "✅ Setup complete!"
echo "📱 Use Telegram commands: /start /deploy /lock /unlock /update_phone /status /logs"
echo "🧠 Don't forget to update your domain registrar with the Route 53 nameservers!"
