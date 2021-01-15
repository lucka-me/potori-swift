#!/bin/sh

#  pre-build.sh
#  Potori
#
#  Created by Lucka on 16/1/2021.
#  
INFO_PLIST="${PROJECT_DIR}/${INFOPLIST_FILE}"

GIT_COMMIT_COUNT=$(git --git-dir="${PROJECT_DIR}/.git" --work-tree="${PROJECT_DIR}" rev-list --count HEAD)

defaults write "$INFO_PLIST" CFBundleVersion "$GIT_COMMIT_COUNT"
