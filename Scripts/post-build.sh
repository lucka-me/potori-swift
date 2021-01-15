#!/bin/sh

#  post-build.sh
#  Potori
#
#  Created by Lucka on 16/1/2021.
#  
INFO_PLIST="${PROJECT_DIR}/${INFOPLIST_FILE}"

mv $INFO_PLIST.bak $INFO_PLIST
