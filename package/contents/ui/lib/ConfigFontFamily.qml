// Version 3

import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

PlasmaComponents3.ComboBox {
    id: configFontFamily
    
    property bool populated: false
    
    Kirigami.FormData.label: i18n("Font Family:")
    
    // Use modern syntax and Plasma theming
    delegate: QQC2.ItemDelegate {
        width: configFontFamily.width
        highlighted: configFontFamily.highlightedIndex === index
        
        contentItem: PlasmaComponents3.Label {
            text: modelData.text
            color: highlighted ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            elide: Text.ElideRight
        }
    }

    // Populate fonts using modern practices
    Component.onCompleted: {
        if (!populated) {
            const fontList = []
            fontList.push({ 
                text: i18nc("Use default font", "Default"),
                value: "" 
            })
            
            const systemFonts = Qt.fontFamilies()
            systemFonts.forEach(font => {
                fontList.push({
                    text: font,
                    value: font
                })
            })
            
            model = fontList
            populated = true
        }
    }
    
    // Modern text styling
    PlasmaComponents3.ToolTip {
        text: i18n("Select the font family for the widget")
    }
}
