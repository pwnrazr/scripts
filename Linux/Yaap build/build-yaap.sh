#!/bin/bash

cd ${PWD}

threads=""
CUSTOM_NAME=""

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
    *)
      echo "Invalid option: $key"
      exit 1
      ;;
  esac
done

#echo current dir: ${PWD}

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
if [ -d ".android-certs" ]; then
  print "${LRD}This build will be signed"
else
  print "${LRD}This build will be unsigned"
fi

DEVICE_DYNAMIC_PARTITIONS=$(grep BOARD_SUPER_PARTITION_GROUPS device/xiaomi/raphael/BoardConfig.mk)
KERNEL_DYNAMIC_PARTITIONS=$(grep CONFIG_INITRAMFS_IGNORE_SKIP_FLAG=y kernel/xiaomi/sm8150/arch/arm64/configs/raphael_defconfig)

if [ "$DEVICE_DYNAMIC_PARTITIONS" != "" ]; then
  DEVICE_DYNAMIC_PARTITIONS=true
else
  DEVICE_DYNAMIC_PARTITIONS=false
fi

if [ "$KERNEL_DYNAMIC_PARTITIONS" != "" ]; then
  KERNEL_DYNAMIC_PARTITIONS=true
else
  KERNEL_DYNAMIC_PARTITIONS=false
fi

if [ "$DEVICE_DYNAMIC_PARTITIONS" = "$KERNEL_DYNAMIC_PARTITIONS" ]; then
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

if [ -n "$(find out/target/product/raphael -name 'YAAP-*.zip')" ]; then

    original_filename=$(basename out/target/product/raphael/YAAP-*.zip)
    new_filename="${original_filename%%.zip}${CUSTOM_NAME}.zip"

    current_build_dir="$builds_directory${new_filename%%.zip}/"
    mkdir "$current_build_dir"

    print "${CYN}Copying sha256sum and recovery.img"
    mv out/target/product/raphael/YAAP-*.zip.sha256sum "$current_build_dir"
    cp "$recovery_img" "$current_build_dir"
 
    if [ -e "$super_empty_img" ]; then
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
