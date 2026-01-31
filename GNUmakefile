IDRC?=idris2

PACKAGE=sodium.ipkg

SRCDIR=source/
BLDDIR=build/

SOURCES!=find source/ -type f -name "*.idr"

NAME      =sodium
VERSION   =0.0.0
COMPRESSED=$(NAME).tar.bz

DISTDIR=$(NAME)-$(VERSION)/

.MAIN:  $(EXECUTABLE)
.PHONY: dist run clean

$(BLDDIR): $(SOURCES) $(PACKAGE)
	@echo "BUILDING LIBRARY"
	@$(IDRC) --build $(PACKAGE)

dist: $(EXECUTABLE)
	@echo "DIST\t$(EXECUTABLE)"
	@mkdir $(DISTDIR)
	@cp -r build/* $(DISTDIR)
	@tar cvf $(COMPRESSED) $(DISTDIR)*

run: $(EXECUTABLE)
	@echo "RUN\t$(EXECUTABLE)"
	@exec $(EXECUTABLE)

clean:
	@echo "RM\t$(BLDDIR) $(DISTDIR) $(COMPRESSED)"
	@rm -rf $(BLDDIR) $(DISTDIR) $(COMPRESSED)
