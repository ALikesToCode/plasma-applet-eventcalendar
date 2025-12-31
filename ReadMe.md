Note: This project has been updated for KDE Plasma 6 compatibility.

This is a fork of the original Event Calendar applet, featuring several quality-of-life improvements and a fix for Google Calendar synchronization. While it is functional, there may still be minor issues, please report them in the Issues tab.

<hr>

# Event Calendar Updated version
This is an updated version that I modified for my own needs, with fix for Google Calender and quality of life improvements. 


Plasmoid for a calendar+agenda with weather that syncs to Google Calendar.

## Screenshots

![](https://i.imgur.com/qdJ71sb.jpg)
![](https://i.imgur.com/Ow8UlFj.jpg)




## A) Install via GitHub

```
git clone -b plasma-6 https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

To update, run the `sh ./update` script. It will run a `git pull` then reinstall the applet. Please note this script will restart plasmashell (so you don't have to relog)!



## Update to GitHub master

If you're asked to test something, you can do so by installing the latest unreleased code.

Beforehand, uninstall the AUR version if you are running Arch (you can reinstall after testing).

Then install pen the Terminal and run the following commands. Please note the install script will restart plasmashell so that you don't have to relog.

```
sudo apt install git
git clone https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install --restart
```

When you've finished testing, you may wish to reinstall the KDE Store or AUR version. First uninstall the widget with the following command, then reinstall your desired version of the widget.

```
sh ./uninstall
```

## Configure

### Google Calendar

1. Right click the calendar > Event Calendar Settings > Google Calendar.
2. Open the login link in your browser, sign in, and grant access.
3. Choose a Redirect Mode:
   - Localhost (default): click Add Account with an empty field to auto-capture, or paste the localhost URL (or just the `code=` value).
   - Helper page: click Add Account with an empty field so the helper can send the code automatically. If it cannot, copy the code manually.
4. Helper page: https://alikestocode.github.io/plasma-applet-eventcalendar/
5. Click Submit (or Add Account).
6. Choose which calendars and tasks to sync. Use Refresh if the list does not load.
7. Click Apply to save your settings.

### Weather

1. Open the Weather tab and enter your OpenWeatherMap city id.
2. If the search cannot find your city, try searching with `site:openweathermap.org/city YOUR_CITY` (example: [Toronto](https://www.google.ca/search?q=site%3Aopenweathermap.org%2Fcity+toronto)).
