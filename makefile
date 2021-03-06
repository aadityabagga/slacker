NAME = asbt
VER = 2.1.2
install = /usr/bin/install
rm = /usr/bin/rm
shell = /bin/bash
DESTDIR =
BINDIR = /usr/bin
DOCDIR = /usr/doc/$(NAME)-$(VER)
MANDIR = /usr/man/man8
CONDIR = /etc/asbt

install: 
	$(install) -d $(DESTDIR)$(BINDIR)
	$(install) -d $(DESTDIR)$(DOCDIR)
	$(install) -d $(DESTDIR)$(MANDIR)
	$(install) -d $(DESTDIR)$(CONDIR)
	$(install) -m755 bin/asbt.sh $(DESTDIR)$(BINDIR)/asbt
	$(install) -m644 README.md $(DESTDIR)$(DOCDIR)
	$(install) -m644 COPYING $(DESTDIR)$(DOCDIR)
	$(install) -m644 Changelog $(DESTDIR)$(DOCDIR)
	$(install) -m644 doc/Examples $(DESTDIR)$(DOCDIR)
	$(install) -m644 makefile $(DESTDIR)$(DOCDIR)
	$(install) -m644 man/asbt.8 $(DESTDIR)$(MANDIR)
	$(install) -m644 conf/asbt.conf $(DESTDIR)$(CONDIR)

uninstall: 
	$(rm) $(DESTDIR)$(BINDIR)/$(NAME)
	$(rm) $(DESTDIR)$(MANDIR)/$(NAME).1
	$(rm) -r $(DESTDIR)$(DOCDIR)
