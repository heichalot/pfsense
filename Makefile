
LOGFILE?= ${.CURDIR}/build.log
_uid!=  id -u

_gitbranch!= git branch --show-current
_product= Senseless
corepath= tmp/${_product}_${_gitbranch}_amd64-core
pkgpath= /usr/local/poudriere/data/packages/${_product}_${_gitbranch}_amd64-${_product}_${_gitbranch}
pkg_log_dir= /usr/local/poudriere/data/logs/bulk/latest-per-pkg

check:
.if ${_uid} != 0
	@echo "you are not root"
	@false
.endif
	@echo "building from branch ${_gitbranch} this should be api"

clean: check
	chflags -R noschg tmp || true
	rm -rf tmp
	rm -f build.conf
	zfs destroy -r zroot/poudriere || true
	rm -rf /usr/local/etc/poudriere.d

build.conf: check
	echo "export PRODUCT_NAME=\"${_product}\"" > $@
	# FIXME replace with external dns
	echo "export STAGING_HOSTNAME=10.42.1.20" >> $@
	echo "export PRODUCT_URL=\"https://www.yahoo.com\"" >> $@
	echo "export VENDOR_NAME=\"Yeske\"" >> $@
	echo "export DO_NOT_SIGN_PKG_REPO=YES" >> $@
	echo "export FREEBSD_BRANCH=${_gitbranch}" >> $@
	echo "export POUDRIERE_PORTS_GIT_BRANCH=${_gitbranch}" >> $@

everything: build.conf
	${.CURDIR}/build.sh --setup-poudriere > ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-poudriere-ports >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-pkg-repo >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh -i iso memstickmfs >> ${LOGFILE} 2>&1

iso: build.conf
	${.CURDIR}/build.sh --setup-poudriere > ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-poudriere-ports >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-pkg-repo >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh -i iso >> ${LOGFILE} 2>&1

memstickmfs: build.conf
	${.CURDIR}/build.sh --setup-poudriere > ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-poudriere-ports >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-pkg-repo >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh -i memstickmfs >> ${LOGFILE} 2>&1

packages: build.conf
	${.CURDIR}/build.sh --setup-poudriere > ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-poudriere-ports >> ${LOGFILE} 2>&1
	${.CURDIR}/build.sh --update-pkg-repo >> ${LOGFILE} 2>&1

buildtime:
	@for file in ${pkg_log_dir}/*/*/*.log; do \
		ts="`tail -1 $${file} | sed 's|build time: ||'`"; \
		logdir="`dirname $${file}`"; \
		bobdir="`dirname $${logdir}`"; \
		str="`basename $${bobdir}`"; \
		echo "$${ts} $${str}"; \
	done | sort -n

shit:
	@for logfile in ${pkg_log_dir}/*/*/*.log; do \
		ts="`tail -1 $${logfile} | sed 's|build time: ||'`"; \
		logdir="`dirname $${logfile}`"; \
		echo "`logdir $${logdir}`"; \
		dir="`dirname $${logdir}`"; \
		logdir="`dirname $${logdir}`"; \
		logdir="`basename $${logdir}`"; \
		echo "$${ts} $${logdir} $${"; \
	done | sort -n

www: check
	rsync -avvz -e ssh ${corepath} root@10.42.1.14:/var/www/html/
	rsync -avvz -e ssh ${pkgpath} root@10.42.1.14:/var/www/html/

prep: check
	curl -V || pkg install -y curl
	rsync --version > /dev/null || pkg install -y rsync
	screen -v || pkg install -y screen
	vmdktool -V || pkg install -y vmdktool
	gtar --version > /dev/null || pkg install -y gtar
	xml --version || pkg install -y xmlstarlet
	qemu-x86_64-static -h > /dev/null || pkg install -y qemu-user-static

synclocalchanges:
	cp /etc/inc/*.inc src/etc/inc/
	cp /usr/local/captiveportal/index.php src/usr/local/captiveportal/
	cp /usr/local/www/*.php src/usr/local/www/

syncfromgit:
	cp src/etc/inc/*.inc /etc/inc/
	cp src/usr/local/captiveportal/index.php /usr/local/captiveportal/
	cp src/usr/local/www/*.php /usr/local/www/
