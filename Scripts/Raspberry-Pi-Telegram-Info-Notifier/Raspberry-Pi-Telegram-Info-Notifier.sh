#!/bin/bash

# Check if running with sudo rights
if [ "$EUID" -ne 0 ]; then
    echo "Please run with sudo rights."
    exit 1
fi

# Telegram Bot API Token
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"

# Your Telegram Chat ID
TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# Directory for log file
LOG_DIR="/home/YOUR_USERNAME/scripts"

# Log file
LOG_FILE="$LOG_DIR/Raspberry-Info.txt"

# Function to send message to Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$(echo -e "$message")"
}

# Get Raspberry Pi information
Hostname=$(hostname)
Raspberry_Model=$(cat /proc/device-tree/model)
Raspberry_SN=$(cat /proc/cpuinfo | grep Serial | cut -d ' ' -f 2)
Raspberry_Revision=$(cat /proc/cpuinfo | grep Revision | cut -d ' ' -f 2)
Raspberry_Memory=$(free -h --si | awk '/Mem:/ {print $2}')

# Get SD card information
SD_Card_Vendor=$(lshw -c disk -class disk | awk '/vendor/ {print $2}')
SD_Card_Product=$(lshw -c disk -class disk | awk '/product/ {print $2}')
SD_Card_SN=$(lshw -c disk -class disk | awk '/serial/ {print $2}')
SD_Card_Capacity=$(lshw -short -C disk | awk '/\/dev\/mmcblk0/ {getline; print $4}')
SD_Card_Date=$(lshw -c disk -class disk | awk '/date/ {print $2}')

# Get interface information
Interface_LAN=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^e|en' | head -n1)
MAC_LAN=$(ip link show $Interface_LAN | awk '/ether/ {print $2}')
Interface_WLAN=$(ip -o link show | awk -F': ' '{print $2}' | grep -E '^w' | head -n1)
MAC_WLAN=$(ip link show $Interface_WLAN | awk '/ether/ {print $2}')

# Check if the log file exists
if [ ! -e "$LOG_FILE" ]; then
  # If the log file doesn't exist, create it and insert the original values
  echo "$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
  echo "Initial Records" >> "$LOG_FILE"
  echo "Hostname: $Hostname" >> "$LOG_FILE"
  echo "Raspberry Pi" >> "$LOG_FILE"
  echo "R Pi Model: $Raspberry_Model" >> "$LOG_FILE"
  echo "R Pi Serial: $Raspberry_SN" >> "$LOG_FILE"
  echo "R Pi Revision: $Raspberry_Revision" >> "$LOG_FILE"
  echo "R Pi Memory: $Raspberry_Memory" >> "$LOG_FILE"
  echo "SD Card" >> "$LOG_FILE"
  echo "SD Vendor: $SD_Card_Vendor" >> "$LOG_FILE"
  echo "SD Product: $SD_Card_Product" >> "$LOG_FILE"
  echo "SD Serial: $SD_Card_SN" >> "$LOG_FILE"
  echo "SD Capacity: $SD_Card_Capacity" >> "$LOG_FILE"
  echo "SD Date: $SD_Card_Date" >> "$LOG_FILE"
  echo "Interfaces" >> "$LOG_FILE"
  echo "MAC eth0: $MAC_LAN" >> "$LOG_FILE"
  echo "MAC wlan0: $MAC_WLAN" >> "$LOG_FILE"
  # Prepare message
  message="\n\n*** Initial Records ***\n\n$Hostname\n\nRaspberry Pi\nModel: $Raspberry_Model\nSerial: $Raspberry_SN\nRevision: $Raspberry_Revision\nMemory: $Raspberry_Memory\n\nSD Card\nVendor: $SD_Card_Vendor\nProduct: $SD_Card_Product\nSerial: $SD_Card_SN\nCapacity: $SD_Card_Capacity\nDate: $SD_Card_Date\n\nInterfaces\nMAC eth0: $MAC_LAN\nMAC wlan0: $MAC_WLAN"

  # Append the updated information to the log file
  echo "MESSAGE_SENT=true" >> "$LOG_FILE"

  # Send message to Telegram
  send_telegram_message "$message" > /dev/null 2>&1  # Redirect both stdout and stderr to /dev/null
else
  # Check if components have changed
  messageRPi=""
  messageSD=""
  messageMACeth0=""
  messageMACwlan0=""
  if [ "$Raspberry_SN" != "$(sed -n '/R Pi Serial:/ s/.*: //p' "$LOG_FILE" | tail -n 1)" ]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
      messageRPi+="Raspberry Pi Serial has changed!"
      echo "$messageRPi" >> "$LOG_FILE"
      echo "Raspberry Pi (Updated)" >> "$LOG_FILE"
      echo "R Pi Model: $Raspberry_Model" >> "$LOG_FILE"
      echo "R Pi Serial: $Raspberry_SN" >> "$LOG_FILE"
      echo "R Pi Revision: $Raspberry_Revision" >> "$LOG_FILE"
      echo "R Pi Memory: $Raspberry_Memory" >> "$LOG_FILE"
  fi

  if [ "$SD_Card_SN" != "$(sed -n '/SD Serial:/ s/.*: //p' "$LOG_FILE" | tail -n 1)" ]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
      messageSD+="SD Card Serial has changed!"
      echo "$messageSD" >> "$LOG_FILE"
      echo "SD Card (Updated)" >> "$LOG_FILE"
      echo "SD Vendor: $SD_Card_Vendor" >> "$LOG_FILE"
      echo "SD Product: $SD_Card_Product" >> "$LOG_FILE"
      echo "SD Serial: $SD_Card_SN" >> "$LOG_FILE"
      echo "SD Capacity: $SD_Card_Capacity" >> "$LOG_FILE"
      echo "SD Date: $SD_Card_Date" >> "$LOG_FILE"
  fi

  if [ "$MAC_LAN" != "$(sed -n '/MAC eth0:/ s/.*: //p' "$LOG_FILE" | tail -n 1)" ]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
      messageMACeth0+="MAC eth0 has changed!"
      echo "$messageMACeth0" >> "$LOG_FILE"
      echo "MAC eth0 (Updated)" >> "$LOG_FILE"
  fi

  if [ "$MAC_WLAN" != "$(sed -n '/MAC wlan0:/ s/.*: //p' "$LOG_FILE" | tail -n 1)" ]; then
      echo "$(date +"%Y-%m-%d %H:%M:%S")" >> "$LOG_FILE"
      messageMACwlan0+="MAC wlan0 has changed!"
      echo "$messageMACwlan0" >> "$LOG_FILE"
      echo "MAC wlan0 (Updated)" >> "$LOG_FILE"
  fi

  # If there are changes, update log and send message
  if [ -n "$messageRPi" ] || [ -n "$messageSD" ] || [ -n "$messageMACeth0" ] || [ -n "$messageMACwlan0" ]; then
      echo "MESSAGE_SENT=true" >> "$LOG_FILE"

      # Prepare message
      message="\n\n*** Updated Records ***\n$messageRPi $messageSD $messageMACeth0 $messageMACwlan0\n\n$Hostname\n\nRaspberry Hardware Info\nRaspberry Pi\nModel: $Raspberry_Model\nSerial: $Raspberry_SN\nRevision: $Raspberry_Revision\nMemory: $Raspberry_Memory\n\nSD Card\nVendor: $SD_Card_Vendor\nProduct: $SD_Card_Product\nSerial: $SD_Card_SN\nCapacity: $SD_Card_Capacity\nDate: $SD_Card_Date\n\nInterfaces\nMAC eth0: $MAC_LAN\nMAC wlan0: $MAC_WLAN"

      # Send message to Telegram
      send_telegram_message "$message" > /dev/null 2>&1  # Redirect both stdout and stderr to /dev/null
  fi
fi
