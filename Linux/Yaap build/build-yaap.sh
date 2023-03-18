#!/bin/bash

cd ${PWD}

threads=""
CUSTOM_NAME=""
BUILD_SIGNED=false # build unsigned by default for now
BUILD_DYNAMIC=""
BUILD_TYPE=""

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'
YEL='\033[1;33m'
CYN='\033[1;36m'

function print()
{
	echo -e ${1} "\r${2}${NC}"
}

function cleanup()
{
  if [[ "$BUILD_SIGNED" = true ]]; then
    rm .android-certs # This should be a symbolic link NOT the actual folder
  fi

  if [[ -e ".repo/local_manifests/yaap_manifest.xml-bak" ]]; then
    print "${CYN}Restoring previous yaap_manifest.xml"
    mv .repo/local_manifests/yaap_manifest.xml-bak .repo/local_manifests/yaap_manifest.xml
  fi
}

function setup_signed()
{
  ln -s ~/.android-certs .android-certs
}

function sync_build_type()
{
  if [[ -e ".repo/local_manifests/yaap_manifest.xml" ]]; then
    mv .repo/local_manifests/yaap_manifest.xml .repo/local_manifests/yaap_manifest.xml-bak
  fi

  if [[ "$BUILD_DYNAMIC" = true ]]; then
    print "${CYN}Getting dynamic partitions yaap_manifest.xml"
    wget -q https://raw.githubusercontent.com/pwnrazr/device_xiaomi_raphael/thirteen-dynamic-partitions/yaap_manifest.xml -P .repo/local_manifests/
  elif [[ "$BUILD_DYNAMIC" = false ]]; then
    print "${CYN}Getting non dynamic partitions yaap_manifest.xml"
    wget -q https://raw.githubusercontent.com/pwnrazr/device_xiaomi_raphael/thirteen/yaap_manifest.xml -P .repo/local_manifests/
  fi

  print "${CYN}Synchronizing device and kernel tree"
  repo sync -q device/xiaomi/raphael/ kernel/xiaomi/sm8150/
}

function check_otacert()
{
  signed_otacert="/mnt/c/Users/AmirA/OneDrive/Documents/YAAP custom/otacerts/otacert-signed"
  unsigned_otacert="/mnt/c/Users/AmirA/OneDrive/Documents/YAAP custom/otacerts/otacert-unsigned"
  current_build_otacert="$current_build_dir"original-META-INF/META-INF/com/android/otacert

  if [[ "$BUILD_SIGNED" = true ]]; then
    if cmp -s "$signed_otacert" "$current_build_otacert"; then
      print "${LGR}Current build otacert matches signed otacert"
    else
      print "${RED}Current build otacert doesn't match signed otacert!"
    fi
  else
    if cmp -s "$unsigned_otacert" "$current_build_otacert"; then
      print "${LGR}Current build otacert matches unsigned otacert"
    else
      print "${RED}Current build otacert doesn't match unsigned otacert!"
    fi
  fi
}

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -j)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: Argument for $key is missing"
        exit 1
      fi
      threads="-j$2"
      echo "Threads is now ${threads}"
      shift 2
      ;;
    -n)
      if [[ -z "$2" || "$2" == -* ]]; then
        echo "Error: Argument for $key is missing"
        exit 1
      fi
      CUSTOM_NAME="-$2"
      echo "Custom name: $CUSTOM_NAME"
      shift 2
      ;;
    --sign)
      BUILD_SIGNED=true
      setup_signed
      shift 1
      ;;
    --dynamic)
      if [[ -z "$BUILD_DYNAMIC" ]]; then
        BUILD_DYNAMIC=true
      else
        print "${RED}Both --dynamic and --non-dynamic flags set!"
        exit
      fi
      shift 1
      ;;
    --non-dynamic)
      if [[ -z "$BUILD_DYNAMIC" ]]; then
        BUILD_DYNAMIC=false
      else
        print "${RED}Both --dynamic and --non-dynamic flags set!"
        exit
      fi
      shift 1
      ;;
    *)
      echo "Invalid option: $key"
      exit 1
      ;;
  esac
done

if [[ "$BUILD_DYNAMIC" != "" ]]; then
  sync_build_type
else
  print "${YEL}Building current"
fi

#echo current dir: ${PWD}

export USE_CCACHE=true
export CCACHE_DIR=/home/pwnrazr/dev-stuff/yaap-ccache

export USE_THINLTO_CACHE=true
export THINLTO_CACHE_DIR=/home/pwnrazr/dev-stuff/yaap-thinlto-cache

#export GLOBAL_THINLTO=true

export TARGET_BUILD_GAPPS=true

staging_directory="/mnt/c/Users/AmirA/OneDrive/Documents/YAAP custom/builds/staging/"
builds_directory="/mnt/c/Users/AmirA/OneDrive/Documents/YAAP custom/builds/"

super_empty_img="out/target/product/raphael/obj/PACKAGING/target_files_intermediates/yaap_raphael-target_files-eng.pwnrazr/IMAGES/super_empty.img"
recovery_img=out/target/product/raphael/obj/PACKAGING/target_files_intermediates/yaap_raphael-target_files-eng.pwnrazr/IMAGES/recovery.img

# sanity checks
if [ "$BUILD_SIGNED" = true ]; then
  if [[ -e .android-certs/releasekey.x509.pem ]]; then
    print "${LRD}This build will be signed"
    BUILD_TYPE+="-signed"
  else
    print "${RED}BUILD_SIGNED is set but releasekey does not exist in .android-certs!"
    exit
  fi
else
  if [[ -e .android-certs/releasekey.x509.pem ]]; then
    print "${RED}BUILD_SIGNED is unset but releasekey exists in .android-certs!"
    exit
  else
    print "${LRD}This build will be unsigned"
    BUILD_TYPE+="-unsigned"
  fi
fi

DEVICE_DYNAMIC_PARTITIONS=$(grep BOARD_SUPER_PARTITION_GROUPS device/xiaomi/raphael/BoardConfig.mk)
KERNEL_DYNAMIC_PARTITIONS=$(grep CONFIG_INITRAMFS_IGNORE_SKIP_FLAG=y kernel/xiaomi/sm8150/arch/arm64/configs/raphael_defconfig)

if [[ "$DEVICE_DYNAMIC_PARTITIONS" != "" ]]; then
  DEVICE_DYNAMIC_PARTITIONS=true
else
  DEVICE_DYNAMIC_PARTITIONS=false
fi

if [[ "$KERNEL_DYNAMIC_PARTITIONS" != "" ]]; then
  KERNEL_DYNAMIC_PARTITIONS=true
  BUILD_TYPE+="-dynamic"
else
  KERNEL_DYNAMIC_PARTITIONS=false
  BUILD_TYPE+="-non_dynamic"
fi

if [[ "$DEVICE_DYNAMIC_PARTITIONS" = "$KERNEL_DYNAMIC_PARTITIONS" ]]; then
  print "${LGR}Device and kernel tree match. Dynamic Partitions = $DEVICE_DYNAMIC_PARTITIONS"
else
  print "${RED}Device and kernel tree mismatch!"
  print "${RED}DEVICE_DYNAMIC_PARTITIONS = $DEVICE_DYNAMIC_PARTITIONS"
  print "${RED}KERNEL_DYNAMIC_PARTITIONS = $KERNEL_DYNAMIC_PARTITIONS"
  exit
fi

source build/envsetup.sh

print "${LGR}Time to build!"
lunch yaap_raphael-user && m yaap ${threads}

if [[ -n "$(find out/target/product/raphael -name 'YAAP-*.zip')" ]]; then

    original_filename=$(basename out/target/product/raphael/YAAP-*.zip)
    new_filename="${original_filename%%.zip}${CUSTOM_NAME}${BUILD_TYPE}.zip"

    current_build_dir="$builds_directory${new_filename%%.zip}/"
    mkdir "$current_build_dir"

    print "${CYN}Copying sha256sum and recovery.img"
    mv out/target/product/raphael/YAAP-*.zip.sha256sum "$current_build_dir"
    cp "$recovery_img" "$current_build_dir"
 
    if [[ -e "$super_empty_img" ]]; then
      print "${YEL}Copying super_empty.img"
      cp "$super_empty_img" "$current_build_dir"
    else
      print "${YEL}Not a dynamic partitions build, super_empty.img not found"
    fi

    print "${CYN}Moving $new_filename to staging"
    mv out/target/product/raphael/YAAP-*.zip "$staging_directory${new_filename}"
    cd "$staging_directory"

    print "${CYN}Backing up original META-INF"
    7z x YAAP-*.zip -o"$current_build_dir"original-META-INF META-INF > /dev/null

    print "${CYN}Zipping old update-binary into ${new_filename}"
    7z a YAAP-*.zip META-INF > /dev/null

    print "${CYN}Moving YAAP zip to $current_build_dir"
    mv YAAP-*.zip "$current_build_dir"

    print "${LGR}Build finished"
else
    print "${RED}Build failed! YAAP-.zip not found"
fi

check_otacert
cleanup