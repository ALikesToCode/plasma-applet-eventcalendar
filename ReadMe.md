# Event Calendar Updated version
This is an updated version that I modified for my own needs, with fix for Google Calender and quality of life improvements. 


Plasmoid for a calendar+agenda with weather that syncs to Google Calendar.

## Branch guide

- Plasma 6 (default): `master`
- Plasma 5 (legacy): `plasma-5`
- `plasma-6` is reserved for development/testing.

## Contributing

See `CONTRIBUTING.md` for guidelines and `MAINTENANCE.md` for project status.

## Screenshots

![](https://i.imgur.com/qdJ71sb.jpg)
![](https://i.imgur.com/Ow8UlFj.jpg)




## A) Install via GitHub

Plasma 6 (default branch):

```
git clone https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

Plasma 5 (legacy branch):

```
git clone -b plasma-5 https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install
```

To update, run the `sh ./update` script. It will auto-detect your Plasma version, switch branches if needed, pull updates, and reinstall the applet.



## Update to GitHub master (Plasma 6)

If you're asked to test something, you can do so by installing the latest unreleased code.

Beforehand, uninstall the AUR version if you are running Arch (you can reinstall after testing).

Then open the Terminal and run the following commands. The install script can reload the widget when you pass `--restart`.

```
sudo apt install git
git clone https://github.com/ALikesToCode/plasma-applet-eventcalendar.git eventcalendar
cd eventcalendar
sh ./install --restart
```

For Plasma 5, use the `plasma-5` branch instead:

```
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
