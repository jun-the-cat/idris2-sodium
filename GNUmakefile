IDRC?=idris2

PACKAGE=sodium.ipkg

SRCDIR=source/
BLDDIR=build/

SOURCES!=find source/ -type f -name "*.idr"

SHIM=lib/libshim.so

NAME      =sodium
VERSION   =0.0.0
COMPRESSED=$(NAME)-$(VERSION).tar.bz

DISTDIR=$(NAME)-$(VERSION)/

.MAIN:  $(EXECUTABLE)
.PHONY: dist run clean $(SHIM)

$(BLDDIR): $(SOURCES) $(PACKAGE) $(SHIM)
	@echo "BUILDING LIBRARY"
	@$(IDRC) --build $(PACKAGE)

$(SHIM):
	@echo "BUILDING SHIM"
	@make -sC shim/

dist: $(BLDDIR)
	@echo "DIST\t$(COMPRESSED)"
	@mkdir $(DISTDIR)  $(DISTDIR)lib
	@cp -r build/ttc/* $(DISTDIR)
	@cp -r source/*    $(DISTDIR)
	@cp $(SHIM)        $(DISTDIR)lib
	@cp sodium.ipkg    $(DISTDIR)
	@tar cvf $(COMPRESSED) $(DISTDIR)*

clean:
	@make -sC shim/ clean
	@echo "RM\t$(BLDDIR) $(DISTDIR) $(COMPRESSED)"
	@rm -rf $(BLDDIR) $(DISTDIR) $(COMPRESSED)
