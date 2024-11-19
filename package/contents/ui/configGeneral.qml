import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3

Kirigami.FormLayout {
    id: generalPage
    
    property alias cfg_showAnimation: showAnimationCheckbox.checked
    property alias cfg_counterColor: colorCombo.currentValue
    property alias cfg_incrementStep: incrementSpinBox.value
    property alias cfg_maxValue: maxValueSpinBox.value

    QQC2.CheckBox {
        id: showAnimationCheckbox
        Kirigami.FormData.label: i18n("Appearance:")
        text: i18n("Show animation")
    }

    QQC2.ComboBox {
        id: colorCombo
        Kirigami.FormData.label: i18n("Counter color:")
        model: [
            { text: i18n("Theme color"), value: "" },
            { text: i18n("Red"), value: "#ff0000" },
            { text: i18n("Green"), value: "#00ff00" },
            { text: i18n("Blue"), value: "#0000ff" }
        ]
        textRole: "text"
        valueRole: "value"
        onActivated: cfg_counterColor = currentValue
    }

    QQC2.SpinBox {
        id: incrementSpinBox
        Kirigami.FormData.label: i18n("Increment step:")
        from: 1
        to: 100
    }

    QQC2.SpinBox {
        id: maxValueSpinBox
        Kirigami.FormData.label: i18n("Maximum value:")
        from: 1
        to: 9999
    }
} 