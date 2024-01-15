#!/bin/bash

# Telegram Bot API Token
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"

# Your Telegram Chat ID
TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# Path to a file to store the previous LAN IP
PREVIOUS_IP_FILE="/home/ph03n1x/scripts/previous_ip.txt"

# Get the current LAN IP and hostname
CURRENT_IP=$(hostname -I | awk '{print $1}')
HOSTNAME=$(hostname)

# Debug output
echo "Current IP: $CURRENT_IP"

# Check if the LAN IP has changed
if [ -f "$PREVIOUS_IP_FILE" ]; then
  PREVIOUS_IP=$(cat "$PREVIOUS_IP_FILE")

  if [ "$CURRENT_IP" != "$PREVIOUS_IP" ]; then
    # LAN IP has changed, send message to Telegram
    MESSAGE="LAN IP of $HOSTNAME has changed!\n\nNew IP: $CURRENT_IP"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$MESSAGE"
    
    # Update the previous IP file
    echo "Updated previous IP: $CURRENT_IP"
    echo "$CURRENT_IP" > "$PREVIOUS_IP_FILE"
  fi
else
  # Previous IP file doesn't exist, create it and store the current IP
  echo "Initial run, storing current IP: $CURRENT_IP"
  echo "$CURRENT_IP" > "$PREVIOUS_IP_FILE"
fi
