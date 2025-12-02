#!/system/bin/sh

SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=false
clear

print_modname() {
  cat "$MODPATH/splash.txt"
}

FF_XML_EDIT() {
  local key="$1"
  local value="$2"
  local sys_xml="/system/etc/floating_feature.xml"
  local mod_xml="$MODPATH/system/etc/floating_feature.xml"
  [ -f "$sys_xml" ] || return 1
  mkdir -p "$(dirname "$mod_xml")"
  cp -af "$sys_xml" "$mod_xml"
  sed -i "s|\(<$key>\)[^<]*\(</$key>\)|\1$value\2|g" "$mod_xml"
}

detect_device() {
  local bootloader
  bootloader="$(getprop ro.boot.bootloader)"
  case "$bootloader" in
    *A105*)
      export device_name="Galaxy A10"
      export device_code="a10"
      ;;
    *A205*)
      export device_name="Galaxy A20"
      export device_code="a20"
      ;;
    *A202*)
      export device_name="Galaxy A20e"
      export device_code="a20e"
      ;;
    *A305*)
      export device_name="Galaxy A30"
      export device_code="a30"
      ;;
    *A307*)
      export device_name="Galaxy A30s"
      export device_code="a30s"
      ;;
    *)
      export device_name="Unsupported Device"
      export device_code="unsupported"
      ;;
  esac
  ui_print "- Detected: $device_name"
}

suitable_cam() {
  local device camera_src camera_path="/system/cameradata/camera-feature.xml"
  detect_device
    if [ "$device_code" = "unsupported" ]; then
      ui_print "! Unsupported device"
      return 0
    fi
  camera_src="$MODPATH/camera-feature/$device_code/camera-feature.xml"
    if [ -f "$camera_src" ]; then
      rm -rf /data/user/0/com.sec.android.app.camera
      ui_print "- Applying camera feature for $device_name"
      install -D -m 0644 "$camera_src" "$MODPATH$camera_path"
    else
      ui_print "! Missing camera-feature.xml for $device_name"
    fi
}

gpsu() {
  rm -rf /data/apex
}

patch_floating_feature() {
  ui_print "- Disabling Photo HDR"
  FF_XML_EDIT SEC_FLOATING_FEATURE_MMFW_SUPPORT_PHOTOHDR FALSE
}

apply_permissions() {
  set_perm_recursive "$MODPATH" 0 0 0755 0644
}

verify_build() {
  local build_id
  build_id="$(getprop ro.build.display.id)"
  ui_print "- Checking ROM build ID..."
  if echo "$build_id" | grep -q "equinoX"; then
    ui_print "- Detected equinoX build"
    if [ "$build_id" != "equinoX v5-rc1 – AP3A.240905.015.A2.E146BXXU7DYF56" ]; then
      ui_print "! Build mismatch:"
      ui_print "  Expected: equinoX v5-rc1 – AP3A.240905.015.A2.E146BXXU7DYF56"
      ui_print "  Found:    $build_id"
      abort "- Aborting installation due to unsupported build."
    fi
  else
    if echo "$build_id" | grep -q "FP"; then
      export SKIP_FF_PATCH=true
    else
      ui_print "- Unsupported ROM."
      abort "- Aborting module installation."
    fi
  fi
}

restorecon_reset() {
  ui_print "- Running restorecon over /data/media/0"
  chown -R media_rw:media_rw /data/media/0
  chmod -R 0777 /data/media/0
  restorecon -RF /data/media/0
}

main() {
  print_modname
  verify_build
  suitable_cam
  apply_permissions
  [ "$SKIP_FF_PATCH" != "true" ] && patch_floating_feature
  [ "$SKIP_FF_PATCH" != "true" ] && restorecon_reset
  gpsu
  ui_print "- Module setup completed successfully"
}

main
