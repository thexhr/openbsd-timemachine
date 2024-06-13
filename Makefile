install:
	install -p -m 600 -o root openbsd-timemachine-backup.sh /root/

uninstall:
	rm -f /root/openbsd-timemachine-backup.sh
