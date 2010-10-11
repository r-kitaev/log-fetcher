#!/bin/bash

set -e

CONF_PATH=/etc/default/log-fetcher

if [ -f $CONF_PATH ] ; then
  . $CONF_PATH
fi

cat $LOG_PATH | $PARSER_PATH $1 $2

