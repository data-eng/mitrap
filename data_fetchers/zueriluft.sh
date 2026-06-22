#!/bin/bash

lftp -c 'set cmd:show-status no ; set cmd:verbose no ; set xfer:clobber no ; set ssl:check-hostname no ; open ftp://ftp.zueriluft.ch; user "<user>" "<password>" ; mirror --continue ./ /mnt/web/zueriluft/ ;  bye'

