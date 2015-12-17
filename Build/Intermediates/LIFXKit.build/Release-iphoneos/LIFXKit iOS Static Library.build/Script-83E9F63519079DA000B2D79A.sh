#!/bin/sh
# Create Framework bundle directory structure
#
# Based on https://github.com/jverkoey/iOS-Framework
#

set -e

LFX_PRODUCT_NAME="LIFXKit"
LFX_FRAMEWORK_PATH="${BUILT_PRODUCTS_DIR}/${LFX_PRODUCT_NAME}.framework"

mkdir -p "${LFX_FRAMEWORK_PATH}/Versions/A/Headers"

# Link the "Current" version to "A"
/bin/ln -sfh A "${LFX_FRAMEWORK_PATH}/Versions/Current"
/bin/ln -sfh Versions/Current/Headers "${LFX_FRAMEWORK_PATH}/Headers"
/bin/ln -sfh "Versions/Current/${LFX_PRODUCT_NAME}" "${LFX_FRAMEWORK_PATH}/${LFX_PRODUCT_NAME}"

# The -a ensures that the headers maintain the source modification date so that we don't constantly
# cause propagating rebuilds of files that import these headers.
/bin/cp -a "${TARGET_BUILD_DIR}/${PUBLIC_HEADERS_FOLDER_PATH}/" "${LFX_FRAMEWORK_PATH}/Versions/A/Headers"

