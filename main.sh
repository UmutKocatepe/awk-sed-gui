#!/bin/bash

# Whiptail kontrolü
if ! command -v whiptail &> /dev/null; then
    echo "ERROR: whiptail is not installed!"
    echo "Please install it: sudo apt-get install whiptail"
    exit 1
fi

# YAD kontrolü
if ! command -v yad &> /dev/null; then
    echo "ERROR: yad is not installed!"
    echo "Please install it: sudo apt-get install yad"
    exit 1
fi

# Ana menü - Arayüz seçimi
choice=$(whiptail --title "File Editor - Interface Selection" \
    --menu "Choose the interface type you want to use:" 15 60 2 \
    "1" "GUI Mode (Graphical - YAD)" \
    "2" "TUI Mode (Terminal - Whiptail)" \
    3>&1 1>&2 2>&3)

# Çıkış kontrolü
exitstatus=$?
if [ $exitstatus != 0 ]; then
    exit 0
fi

# Seçime göre ilgili scripti çalıştır
case $choice in
    1)
        if [ -f "./main_gui.sh" ]; then
            bash ./main_gui.sh
        else
            echo "ERROR: main_gui.sh not found!"
            exit 1
        fi
        ;;
    2)
        if [ -f "./main_tui.sh" ]; then
            bash ./main_tui.sh
        else
            echo "ERROR: main_tui.sh not found!"
            exit 1
        fi
        ;;
    *)
        exit 0
        ;;
esac

exit 0
