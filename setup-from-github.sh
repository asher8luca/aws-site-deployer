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
# Print current working directory to check where the script is running
echo "Current working directory: $(pwd)"  # Debugging current directory

# Use relative path for .env file
ENV_FILE="./support-deployer-site/.env"  # Change this to the relative path for the .env file
echo "Looking for .env at: $ENV_FILE"  # Added for debugging

# Check if the .env file exists and load it
if [ -f "$ENV_FILE" ]; then
  # Load the existing .env file from the correct path
  source "$ENV_FILE"
  echo "📦 Loaded existing config from $ENV_FILE"
else
  echo "⚠️ .env file not found in repository! Exiting..."
  exit 1
fi

# Debugging the loaded environment variables
echo "DOMAIN: $DOMAIN"
echo "GITHUB_REPO_URL: $GITHUB_REPO_URL"
echo "S3_BUCKET: $S3_BUCKET"

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
