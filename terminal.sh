#!/bin/bash

PREFIX="${CMD_PREFIX} "

if ! [[ ${GH_COMMENT} == ${PREFIX}* ]]; then
  # Only echo out 2x the prefix's length
  echo "Comment '${GH_COMMENT:0:$(( ${#PREFIX}*2 + 1 ))}...' did not start with '${PREFIX}'. Skipping."
  exit
fi

STDOUT=$(${GH_COMMENT:${#PREFIX}})

echo "::set-output name=exit-code::$(echo $?)"
echo "::set-output name=stdout::$(echo ${STDOUT})"
echo "::set-output name=command::$(echo ${GH_COMMENT:${#PREFIX}})"
