#!/usr/bin/env sh
#
# Copyright (c) 2024, 2025 TNO-ESI
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available
# under the terms of the MIT License which is available at
# https://opensource.org/licenses/MIT
#
# SPDX-License-Identifier: MIT
#


SCRIPT=`readlink -f $0`
SCRIPTPATH=`dirname $SCRIPT`

LANGNAME="${1////}"
LANGTEST="${LANGNAME}.tests"
LANGUITEST="${LANGNAME}.ui.tests"

REPLNAME="some.to.replace"
REPLTEST="${REPLNAME}.tests"
REPLUITEST="${REPLNAME}.ui.tests"

if [ -z "${LANGNAME}" ] ; then
	echo "Usage: ${SCRIPT} <language_dir> [ui]"
	echo "language_dir   Xtext language directory"
	echo "ui             Creates also UI test project"
	exit 1
elif [ ! -d "${LANGNAME}" ] ; then
	echo "Language directory does not exist"
	echo
	echo "Usage: ${SCRIPT} <language_dir> [ui]"
	echo "language_dir   Xtext language directory"
	echo "ui             Creates also UI test project"
	exit 1
fi

if [ -d "${LANGTEST}" ]; then
	echo "Skipped project ${LANGTEST}, directory already exists"
else 
	tar xf create-test-projects.tar "${REPLTEST}"
	mv "${REPLTEST}" "${LANGTEST}"
	find "${LANGTEST}" -type f -exec sed -i s#${REPLNAME}#${LANGNAME}#g {} \;
	
	echo "Created project ${LANGTEST}"
fi

if [ "$2" == "ui" ]; then
	if [ -d "${LANGUITEST}" ]; then
		echo "Skipped project ${LANGUITEST}, directory already exists"
	else 
		tar xf create-test-projects.tar "${REPLUITEST}"
		mv "${REPLUITEST}" "${LANGUITEST}"
		find "${LANGUITEST}" -type f -exec sed -i s#${REPLNAME}#${LANGNAME}#g {} \;
		
		echo "Created project ${LANGUITEST}"
	fi
fi