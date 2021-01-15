#!/bin/sh

#  post-build.sh
#  Potori
#
#  Created by Lucka on 16/1/2021.
#  
INFO_PLIST="${PROJECT_DIR}/${INFOPLIST_FILE}"

defaults write "$INFO_PLIST" CFBundleVersion 1
