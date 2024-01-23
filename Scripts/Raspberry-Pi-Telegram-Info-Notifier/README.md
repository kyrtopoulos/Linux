# Telegram Raspberry Info Project

## Step 1: Download the Telegram Raspberry Info Script
Download the script to a specified directory

`wget -O /path/to/download/directory/Raspberry-Pi-Telegram-Info-Notifier.sh https://raw.githubusercontent.com/kyrtopoulos/Linux/main/Scripts/Raspberry-Pi-Telegram-Info-Notifier/Raspberry-Pi-Telegram-Info-Notifier.sh`

### Step 2: Customize the Script
Open the downloaded script in a text editor to customize configuration variables.

`nano telegram-raspberry-info.sh` 

### Step 3: Make Script Executable

`chmod +x telegram-raspberry-info.sh` 

### Step 4: Edit Cron Jobs

`sudo crontab -e` 

### Step 5: Add Cron Job
Add the following line to run the script daily at 11:00 AM:

`0 11 * * * /path/to/telegram-raspberry-info.sh` 

Replace `/path/to/telegram-raspberry-info.sh` with the actual path.

### Step 6: Restart Cron Service
Restart the cron service to apply the changes.

`sudo systemctl restart cron` 


Now, the script will run daily, collecting Raspberry Pi information and sending it to your Telegram chat. Check the log file for initial and updated records.

Feel free to explore and modify the script according to your preferences or add more functionalities! 
If you have any suggestions or improvements, let me know. 
Happy coding! 😊🔧
