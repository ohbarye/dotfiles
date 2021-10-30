#!/usr/bin/env osascript

tell application "System Preferences" to reveal pane "com.apple.preference.displays"


tell application "System Events"
	tell process "System Preferences" to tell window "Built-in Retina Display" to set _T to a reference to tab group 1

	repeat until _T exists
		delay 0.5
	end repeat

	tell _T
		click radio button "Night Shift"
		click checkbox "Turn On Until Tomorrow"
	end tell
end tell

quit application "System Preferences"

