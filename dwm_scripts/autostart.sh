#!/bin/bash

clash &
# start the picom to make sure alpha effect
picom -b

# start the background picture setup
feh --bg-fill --randomize ~/Pictures/*

nm-applet &

# start the bluetooth mananger
blueman-applet &
