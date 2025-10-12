#!/system/bin/sh

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false
clear

print_modname() {
  cat $MODPATH/splash.txt
}

on_install() {
  ui_print "- Detecting device via bootloader..."
  BOOTLOADER=$(getprop ro.boot.bootloader)
  ui_print "  Bootloader: $BOOTLOADER"

  CAMERA_SRC=""
  CAMERA_PATH="/system/cameradata/camera-feature.xml"

  case "$BOOTLOADER" in
    *A105*)
      CAMERA_SRC="$MODPATH/camera-feature/a10/camera-feature.xml"
      ;;
    *A205*)
      CAMERA_SRC="$MODPATH/camera-feature/a20/camera-feature.xml"
      ;;
    *A202*)
      CAMERA_SRC="$MODPATH/camera-feature/a20e/camera-feature.xml"
      ;;
    *A305*)
      CAMERA_SRC="$MODPATH/camera-feature/a30/camera-feature.xml"
      ;;
    *A307*)
      CAMERA_SRC="$MODPATH/camera-feature/a30s/camera-feature.xml"
      ;;
    *)
      ui_print "  ! Unsupported device: $BOOTLOADER"
      ui_print "  ! Camera feature file will not be selected."
      return 0
      ;;
  esac

  if [ -f "$CAMERA_SRC" ]; then
    rm -rf /data/user/0/com.sec.android.app.camera
    ui_print "- Choosing appropriate camera-feature.xml for the device based on $BOOTLOADER"
    install -D -m 0644 "$CAMERA_SRC" "$MODPATH$CAMERA_PATH"
  else
    ui_print "  ! Missing file for device based on $BOOTLOADER"
  fi
}

set_permissions() {
  set_perm_recursive $MODPATH 0 0 0755 0644
}

print_modname
on_install
set_permissions