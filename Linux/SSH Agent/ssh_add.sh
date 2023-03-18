#!/bin/bash

#eval "$(ssh-agent -s)";ssh-add ~/.ssh/id_ed25519_pwnrazr_sec

if [ -z "$SSH_AUTH_SOCK" ] ; then
	eval "$(ssh-agent -s)"
	ssh-add ~/.ssh/id_ed25519_pwnrazr_sec
	bash -i
else
	echo ssh agent already running
fi
