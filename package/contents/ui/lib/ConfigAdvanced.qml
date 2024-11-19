// Version 7 - Updated for Plasma 6

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasmoid

ColumnLayout {
    id: page
    spacing: Kirigami.Units.smallSpacing

    property var palette: Kirigami.Theme

    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
            id: configTable
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing
            model: []
            clip: true

            Component {
                id: boolControl
                PlasmaComponents.Switch {
                    checked: modelValue
                    onToggled: plasmoid.configuration[modelKey] = checked
                }
            }

            Component {
                id: numberControl
                PlasmaComponents.SpinBox {
                    value: modelValue
                    readonly property bool isInteger: modelConfigType === 'uint' || modelConfigType === 'int' || Number.isInteger(modelValue)
                    from: -Number.MAX_SAFE_INTEGER
                    to: Number.MAX_SAFE_INTEGER
                    stepSize: isInteger ? 1 : 0.1
                    editable: true
                    onValueChanged: plasmoid.configuration[modelKey] = value
                }
            }

            Component {
                id: stringListControl
                PlasmaComponents.TextArea {
                    text: '' + modelValue
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                }
            }

            Component {
                id: stringControl
                PlasmaComponents.TextArea {
                    text: modelValue
                    wrapMode: TextEdit.Wrap
                    onTextChanged: plasmoid.configuration[modelKey] = text
                }
            }

            Component {
                id: base64jsonControl
                PlasmaComponents.TextArea {
                    text: {
                        if (modelValue) {
                            try {
                                const data = JSON.parse(Qt.atob(modelValue))
                                return JSON.stringify(data, null, '  ')
                            } catch (e) {
                                return 'Error parsing JSON: ' + e
                            }
                        }
                        return ''
                    }
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                }
            }

            delegate: RowLayout {
                width: parent.width
                spacing: Kirigami.Units.smallSpacing

                function valueToString(val) {
                    return (val === undefined || val === null) ? '' : String(val)
                }

                readonly property var configDefaultValue: plasmoid.configuration[model.key + 'Default']
                readonly property bool isDefault: valueToString(model.value) == valueToString(model.defaultValue) || 
                                               valueToString(model.value) == valueToString(configDefaultValue)

                PlasmaComponents.TextField {
                    Layout.preferredWidth: 200
                    text: model.key
                    readOnly: true
                    font.bold: !isDefault
                    background: Rectangle {
                        color: "transparent"
                        border.color: parent.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                        radius: Kirigami.Units.smallSpacing
                    }
                }

                PlasmaComponents.TextField {
                    Layout.preferredWidth: 100
                    text: model.stringType || model.configType || model.valueType
                    readOnly: true
                    background: Rectangle {
                        color: "transparent"
                        border.color: parent.activeFocus ? Kirigami.Theme.highlightColor : "transparent"
                        radius: Kirigami.Units.smallSpacing
                    }
                }

                Loader {
                    id: valueControlLoader
                    Layout.fillWidth: true
                    property var modelKey: model.key
                    property var modelValueType: model.valueType
                    property var modelValue: model.value
                    property var modelConfigType: model.configType

                    sourceComponent: {
                        switch(model.valueType) {
                            case 'boolean': return boolControl
                            case 'number': return numberControl
                            case 'object': return stringListControl
                            default:
                                return model.stringType === 'base64json' ? base64jsonControl : stringControl
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: configDefaults
        property bool loading: false
        property bool error: false
        property string source: plasmoid.file("", "config/main.xml")

        signal updated()

        function fetch() {
            const xhr = new XMLHttpRequest()
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    error = xhr.status !== 200
                    if (!error) {
                        parse(xhr.responseXML.documentElement)
                    }
                    loading = false
                    updated()
                }
            }
            loading = true
            xhr.open("GET", source)
            xhr.send()
        }

        function findNode(parentNode, tagName) {
            for (let i = 0; i < parentNode.childNodes.length; i++) {
                const node = parentNode.childNodes[i]
                if (node.nodeName === tagName) return node
            }
            return null
        }

        function findAll(parentNode, tagName, callback) {
            for (let i = 0; i < parentNode.childNodes.length; i++) {
                const node = parentNode.childNodes[i]
                if (node.nodeName === tagName) callback(node)
            }
        }

        function getText(parentNode) {
            for (let i = 0; i < parentNode.childNodes.length; i++) {
                const node = parentNode.childNodes[i]
                if (node.nodeName === '#text') return node.nodeValue
            }
            return null
        }

        function parse(rootNode) {
            clear()
            findAll(rootNode, 'group', function(group) {
                findAll(group, 'entry', function(entry) {
                    const key = entry.attributes['name'].nodeValue
                    const valueType = entry.attributes['type'].nodeValue
                    const defaultNode = findNode(entry, 'default')
                    const value = defaultNode ? getText(defaultNode) : ''
                    const stringType = entry.attributes['stringType']?.nodeValue || ''

                    append({
                        key: key,
                        valueType: valueType,
                        value: value ?? '',
                        stringType: stringType
                    })
                })
            })
        }

        Component.onCompleted: fetch()
    }

    ListModel {
        id: configTableModel
        dynamicRoles: true

        property var keys: []

        Component.onCompleted: {
            const configKeys = plasmoid.configuration.keys()
            keys = configKeys.filter(key => {
                if (key.endsWith('Default')) {
                    const baseKey = key.slice(0, -7)
                    return plasmoid.configuration[baseKey] === undefined
                }
                return true
            })

            for (const key of keys) {
                if (key === 'minimumWidth') break

                const value = plasmoid.configuration[key]
                append({
                    key: key,
                    valueType: typeof value,
                    value: value,
                    configType: null,
                    stringType: null,
                    defaultValue: null
                })
            }
            configTable.model = configTableModel
        }
    }

    Connections {
        target: configDefaults
        function onUpdated() {
            const keys = configTableModel.keys
            for (let i = 0; i < keys.length; i++) {
                const key = keys[i]
                if (key === 'minimumWidth') continue

                const node = configDefaults.get(i)
                if (!node) {
                    console.warn('Missing config default for:', key)
                    continue
                }

                configTableModel.setProperty(i, 'configType', node.valueType.toLowerCase())
                configTableModel.setProperty(i, 'stringType', node.stringType)
                configTableModel.setProperty(i, 'defaultValue', node.value)
            }
        }
    }

    Connections {
        target: plasmoid.configuration
        function onValueChanged(key, value) {
            const keyIndex = configTableModel.keys.indexOf(key)
            if (keyIndex >= 0) {
                configTableModel.setProperty(keyIndex, 'value', value)
            }
        }
    }
}
