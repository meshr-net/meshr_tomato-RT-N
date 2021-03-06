#!/bin/sh
. $meshr/lib/functions.sh
 . $dir/functions.sh

if [ -n "$widgets" ]; then
	[ ! -f "$meshr/etc/config/freifunk-widgets" ] && touch $meshr/etc/config/freifunk-widgets
	for w in $widgets; do
		uci set freifunk-widgets.${w}=widget
		set_defaults "${w}_" freifunk-widgets.${w}
		uci delete profile_$community.${w}
	done
	uci commit profile_$community
	uci_commitverbose "Added widget config." freifunk-widgets
fi
