#!/bin/sh

# Copyright (c) 2022 Matthias Schmidt <xhr@giessen.ccc.de>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

MNTPOIN=/backup
#DUID of the softraid container
OUTER_DUID=$1
#DUID of the disk within the decrypted container
INNER_DUID=$2
#Location to the file containing the passphrase
PASSFILE=$3
#Location to counter file
CNTF=${MNTPOIN}/.counter

#Wrong number of arguments
if[[ -z $OUTER_DUID || -z $INNER_DUID ]]; then
	logger-i -t error "$(basename $0): DUIDs missing. Abort"
	exit1
fi

if[[ -z $PASSFILE ]]; then
	logger-i -t error "$(basename $0): No path to PASSFILE given. Abort"
	exit1
else
	if[[ ! -f $PASSFILE ]]; then
		logger-i -t error "$(basename $0): Cannot open $PASSFILE. Abort"
		exit1
	fi
fi

if[[ -n $(mount | grep {$MNTPOIN}) ]]; then
	logger-i -t error "$(basename $0): Mount point $MNTPOIN is not empty. Abort"
	exit1
fi

bioctl-c C -p $PASSFILE -l ${OUTER_DUID}.a softraid0 > /dev/null || exit 1
logger"$(basename $0): Backup disk successfully bio-attached"

sync

mount-o softdep,noatime ${INNER_DUID}.i $MNTPOIN || exit 1
logger"$(basename $0): Backup disk mounted successfully to $MNTPOIN"

#exit0

#First backup of its kind
if[[ ! -f ${CNTF} ]]; then
	echo"1" > $CNTF
fi

i=$(cat$CNTF)
if[ $((i%8)) -eq 0 ]; then
	logger"$(basename $0): Iteration ${i}, doing a gamma backup"
	rsnapshot-q gamma
elif[ $((i%4)) -eq 0 ]; then
	logger"$(basename $0): Iteration ${i}, doing a beta backup"
	rsnapshot-q beta
else
	logger"$(basename $0): Iteration ${i}, doing an alpha backup"
	rsnapshot-q alpha
fi
echo$((i+=1)) > $CNTF

sync

umount$MNTPOIN || exit 1

logger"$(basename $0): $MNTPOIN successfully unmounted"

bioctl-d $INNER_DUID || exit 1

logger"$(basename $0): disk successfully bio-detached"
