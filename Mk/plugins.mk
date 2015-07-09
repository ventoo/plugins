# Copyright (c) 2015 Franco Fichtner <franco@opnsense.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

all: check

PLUGIN_COMMENT!=	git rev-list HEAD --max-count=1 | cut -c1-9
PLUGIN_DEPENDS+=	opnsense
PLUGIN_PREFIX=		os-

check:
	@[ -n "${PLUGIN_NAME}" ] || echo "PLUGIN_NAME not set"
	@[ -n "${PLUGIN_VERSION}" ] || echo "PLUGIN_VERSION not set"
	@[ -n "${PLUGIN_DESC}" ] || echo "PLUGIN_DESC not set"
	@[ -n "${PLUGIN_MAINTAINER}" ] || echo "PLUGIN_MAINTAINER not set"

mount: check
	mount_unionfs ${.CURDIR}/src ${DESTDIR}/usr/local

umount: check
	umount -f "<above>:${.CURDIR}/src"

install: check
	# move all sources to their destination
	@mkdir -p ${DESTDIR}/usr/local
	@(cd ${.CURDIR}/src; find * -type f) | while read FILE; do \
	    tar -C ${.CURDIR}/src -cpf - $${FILE} | \
	    tar -C ${DESTDIR}/usr/local -xpf -; \
	done
	# finally pretty-print a list of files present
	@(cd ${.CURDIR}/src; find * -type f) | \
	    xargs -n1 printf "/usr/local/%s\n"

manifest: check
	@echo "name: ${PLUGIN_PREFIX}${PLUGIN_NAME}"
	@echo "version: \"${PLUGIN_VERSION}\""
	@echo "origin: opnsense/${PLUGIN_PREFIX}${PLUGIN_NAME}"
	@echo "comment: \"${PLUGIN_COMMENT}\""
	@echo "desc: \"${PLUGIN_DESC}\""
	@echo "maintainer: ${PLUGIN_MAINTAINER}"
	@echo "www: https://opnsense.org/"
	@echo "prefix: /"
	@echo "deps: {"
	@for DEP in ${PLUGIN_DEPENDS}; do \
		pkg query '  %n: { version: "%v", origin: "%o" }' $${DEP}; \
	done
	@echo "}"

collect: check
	# collect known files present in system
	@(cd ${.CURDIR}/src; find * -type f) | \
	    (xargs -n1 tar -C /usr/local -cpf -) | \
	    tar -C ${.CURDIR}/src -xpf -

remove: check
	# remove known files and directories from system
	@(cd ${.CURDIR}/src; find * -type f) | \
	    xargs -n1 -I% rm -f ${DESTDIR}/usr/local/%
	@(cd ${.CURDIR}/src; find * -type d) | \
	    xargs -n1 -I% rmdir ${DESTDIR}/usr/local/%

clean: check
	@git reset -q . && git checkout -f . && git clean -xdqf .

.PHONY:	check