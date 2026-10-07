This branch supports Plasma 5. For Plasma 6, use the `master` branch.

<hr>

# Event Calendar Updated version
This is an updated version that I modified for my own needs, with fix for Google Calender and quality of life improvements. 


Plasmoid for a calendar+agenda with weather that syncs to Google Calendar.

## Screenshots

![](https://i.imgur.com/qdJ71sb.jpg)
![](https://i.imgur.com/Ow8UlFj.jpg)




## A) Install via GitHub

```
git clone -b plasma-5 https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

To update, run the `sh ./update` script. It detects your Plasma version, selects `plasma-5` for Plasma 5 or `master` for Plasma 6, pulls updates, and reinstalls the applet.



## Update to the latest Plasma 5 code

If you're asked to test something, you can do so by installing the latest unreleased code.

Beforehand, uninstall the AUR version if you are running Arch (you can reinstall after testing).

Then install pen the Terminal and run the following commands. Please note the install script will restart plasmashell so that you don't have to relog.

```
sudo apt install git
git clone -b plasma-5 https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install --restart
```

When you've finished testing, you may wish to reinstall the KDE Store or AUR version. First uninstall the widget with the following command, then reinstall your desired version of the widget.

```
sh ./uninstall
```

## Configure

1. Right click the Calendar > Event Calendar Settings > Google Calendar
2. Copy the Code and enter it at the given link. Keep the settings window open.
3. After the settings window says it's synched, click apply.
4. Go to the Weather Tab > Enter your city id for OpenWeatherMap. If their search can't find your city, try googling it with [site:openweathermap.org/city](https://www.google.ca/search?q=site%3Aopenweathermap.org%2Fcity+toronto).


## Testing

Run the script and import regressions with Node.js 18 or later:

```bash
node --test tests/*.test.js
shellcheck -x --severity=warning install update uninstall lib/package-metadata.sh
```

On a Plasma 5 system with the Qt 5 test runner installed, check command execution and startup component loading:

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software qmltestrunner -input tests
```
