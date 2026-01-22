#!/usr/bin/env bash
set -euo pipefail

file="package/contents/ui/TimeModel.qml"

if ! grep -q "property var allTimezones: Qt.binding" "$file"; then
  echo "Expected allTimezones to use Qt.binding in $file"
  exit 1
fi

if ! grep -q "onNewData:" "$file"; then
  echo "Expected Plasma5Support.DataSource to use onNewData: in $file"
  exit 1
fi
