#!/bin/bash

# --- Clone Private Deployment Scripts First ---
PRIVATE_DEPLOY_REPO="git@github.com:asher8luca/support-deployer-site.git"
DEPLOY_DIR="support-deployer-site"

# Clone or pull the latest version
if [ ! -d "$DEPLOY_DIR" ]; then
  echo "📥 Cloning private deployment repo..."
  git clone "$PRIVATE_DEPLOY_REPO"
else
  echo "📁 Pulling latest from private deployment repo..."
  cd "$DEPLOY_DIR" && git pull && cd ..
fi

# --- Configurable Setup (Do not prompt if .env file exists) ---
# Use absolute path to avoid issues with $HOME and relative paths
ENV_FILE="/home/cloudshell-user/$DEPLOY_DIR/.env"
echo "Looking for .env in: $ENV_FILE"  # Added for debugging
if [ -f "$ENV_FILE" ]; then
  # Load the existing .env file from the correct path
  source "$ENV_FILE"
  echo "📦 Loaded existing config from $ENV_FILE"
else
  echo "⚠️ .env file not found in repository! Exiting..."
  exit 1
fi

# --- Clone Static Site ---
echo "📥 Cloning static site repo..."
git clone "$GITHUB_REPO_URL" static-html || (cd static-html && git pull)

# --- Start Telegram Bot ---
echo "📲 Launching Telegram bot..."
tmux new-session -d -s deploybot "cd $DEPLOY_DIR && python3 telegram_deploy_bot.py"

# --- Run CloudFront Static Site Setup ---
echo "🚀 Running deployment script..."
cd "$DEPLOY_DIR"
chmod +x cloudfront_static_site_setup.sh
./cloudfront_static_site_setup.sh

# --- Done ---
echo -e "\n✅ Setup complete!"
echo "🔧 Domain: $DOMAIN"
echo "💬 Telegram Bot now listening..."
echo "📄 Site deployed from: $GITHUB_REPO_URL"
echo "🧠 Remember to update registrar to use Route 53 nameservers!"
