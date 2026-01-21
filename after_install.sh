#!/bin/bash
set -e

APP_DIR="$HOME/nodejs-ec2-with-codedeploy"

### --- FIX AWS CLI PATH --- ###
export PATH=/usr/local/bin:/usr/bin:/bin:$PATH
echo "AWS CLI PATH: $(which aws)"

### --- COPY APP DIRECTORY --- ###
# Ensure ubuntu owns temp folder
sudo chown -R ubuntu:ubuntu /tmp/nodejs-ec2-with-codedeploy

# Remove old folder if exists
if [ -d "$APP_DIR" ]; then
  rm -rf "$APP_DIR"
fi

# Copy new release
cp -r /tmp/nodejs-ec2-with-codedeploy "$APP_DIR"
chown -R ubuntu:ubuntu "$APP_DIR"

### --- LOAD NVM AND NODE 22.15.0 --- ###
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install 22.15.0
nvm use 22.15.0
echo "Using Node version: $(node -v)"

# ✅ Add Node bin directory to PATH so pm2 is found
export PATH="$NVM_DIR/versions/node/$(nvm version)/bin:$PATH"

echo "Using Node version: $(node -v)"
echo "Using NPM version: $(npm -v)"
echo "Checking PM2: $(which pm2 || echo 'pm2 not found')"

cd "$APP_DIR"

# ### --- RETRIEVE SECRETS --- ###
# SECRETS_JSON=$(/usr/bin/aws secretsmanager get-secret-value \
#   --secret-id test \
#   --query SecretString \
#   --output text \
#   --region us-east-1)

# echo "$SECRETS_JSON" | jq -r 'to_entries | .[] | "\(.key)=\(.value)"' > .env

### --- INSTALL, BUILD, AND ZERO-DOWNTIME RELOAD --- ###
npm install --frozen-lockfile

# --- Install PM2 if not already installed ---
if ! command -v pm2 >/dev/null 2>&1; then
  npm install -g pm2
fi
# Zero-downtime reload or start if not running
pm2 reload web --update-env || pm2 start "npm start" --name web --cwd "$APP_DIR"

# Persist PM2 process list across reboots
pm2 save
