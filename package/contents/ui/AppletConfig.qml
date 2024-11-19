import QtQuick 2.15
import org.kde.kirigami 2.20 as Kirigami

import "lib"
import "lib/ColorUtil.js" as ColorUtil

QtObject {
    id: config

    property bool showIconOutline: plasmoid.configuration.showOutlines

    property color alternateBackgroundColor: {
        var textColor = Kirigami.Theme.textColor
        var bgColor = Kirigami.Theme.backgroundColor
        if (ColorUtil.hasEnoughContrast(textColor, bgColor)) {
            return bgColor
        } else {
            return ColorUtil.setAlpha(textColor, 0.1)
        }
    }

    property color meteogramTextColorDefault: Kirigami.Theme.textColor
    property color meteogramScaleColorDefault: ColorUtil.lerp(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.9)
    property color meteogramPrecipitationRawColorDefault: "#acd"
    property color meteogramPositiveTempColorDefault: "#900"
    property color meteogramNegativeTempColorDefault: "#369"
    property color meteogramIconColorDefault: Kirigami.Theme.textColor

    property color meteogramTextColor: plasmoid.configuration.meteogramTextColor || meteogramTextColorDefault
    property color meteogramScaleColor: plasmoid.configuration.meteogramGridColor || meteogramScaleColorDefault
    property color meteogramPrecipitationRawColor: plasmoid.configuration.meteogramRainColor || meteogramPrecipitationRawColorDefault
    property color meteogramPrecipitationColor: ColorUtil.setAlpha(meteogramPrecipitationRawColor, 0.6)
    property color meteogramPrecipitationTextColor: Qt.tint(meteogramTextColor, ColorUtil.setAlpha(meteogramPrecipitationRawColor, 0.3))
    property color meteogramPrecipitationTextOutlineColor: showIconOutline ? Kirigami.Theme.backgroundColor : "transparent"
    property color meteogramPositiveTempColor: plasmoid.configuration.meteogramPositiveTempColor || meteogramPositiveTempColorDefault
    property color meteogramNegativeTempColor: plasmoid.configuration.meteogramNegativeTempColor || meteogramNegativeTempColorDefault
    property color meteogramIconColor: plasmoid.configuration.meteogramIconColor || meteogramIconColorDefault

    property color agendaHoverBackground: alternateBackgroundColor
    property color agendaInProgressColorDefault: Kirigami.Theme.highlightColor
    property color agendaInProgressColor: plasmoid.configuration.agendaInProgressColor || agendaInProgressColorDefault

    property int agendaColumnSpacing: 10 * Kirigami.Units.devicePixelRatio
    property int agendaDaySpacing: plasmoid.configuration.agendaDaySpacing * Kirigami.Units.devicePixelRatio
    property int agendaEventSpacing: plasmoid.configuration.agendaEventSpacing * Kirigami.Units.devicePixelRatio
    property int agendaWeatherColumnWidth: 60 * Kirigami.Units.devicePixelRatio
    property int agendaWeatherIconSize: plasmoid.configuration.agendaWeatherIconHeight * Kirigami.Units.devicePixelRatio
    property int agendaDateColumnWidth: 50 * Kirigami.Units.devicePixelRatio + agendaColumnSpacing * 2
    property int eventIndicatorWidth: 2 * Kirigami.Units.devicePixelRatio

    property int agendaFontSize: plasmoid.configuration.agendaFontSize === 0 ? Kirigami.Theme.defaultFont.pixelSize : plasmoid.configuration.agendaFontSize * Kirigami.Units.devicePixelRatio

    property int timerClockFontHeight: 40 * Kirigami.Units.devicePixelRatio
    property int timerButtonWidth: 48 * Kirigami.Units.devicePixelRatio

    property int meteogramIconSize: 24 * Kirigami.Units.devicePixelRatio
    property int meteogramColumnWidth: 32 * Kirigami.Units.devicePixelRatio

    property QtObject icalCalendarList: Base64Json {
        configKey: 'icalCalendarList'
    }

    property ListModel icalCalendarListModel: Base64JsonListModel {
        configKey: 'icalCalendarList'
    }

    readonly property string clockFontFamily: plasmoid.configuration.clockFontFamily || Kirigami.Theme.defaultFont.family
    readonly property int lineWeight1: plasmoid.configuration.clockLineBold1 ? Font.Bold : Font.Normal
    readonly property int lineWeight2: plasmoid.configuration.clockLineBold2 ? Font.Bold : Font.Normal

    readonly property string localeTimeFormat: Qt.locale().timeFormat(Locale.ShortFormat)
    readonly property string localeDateFormat: Qt.locale().dateFormat(Locale.ShortFormat)
    readonly property string line1TimeFormat: plasmoid.configuration.clockTimeFormat1 || localeTimeFormat
    readonly property string line2TimeFormat: plasmoid.configuration.clockTimeFormat2 || localeDateFormat
    readonly property string combinedFormat: {
        if (plasmoid.configuration.clockShowLine2) {
            return line1TimeFormat + '\n' + line2TimeFormat
        } else {
            return line1TimeFormat
        }
    }
    readonly property bool clock24h: {
        var is12hour = combinedFormat.toLowerCase().indexOf('ap') >= 0
        return !is12hour
    }
}
