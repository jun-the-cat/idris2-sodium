CC?=cc

SOURCE=shim.c
OBJECT=shim.o
HEADER=shim.h

CFLAGS=-Wall -Wextra -Werror
LIBS  =-lsodium

SO=../lib/libshim.so

.MAIN: $(SO)
.PHONY: clean

$(SO): $(OBJECT)
	@echo "CC\tlib/libshim.so"
	@mkdir -p ../lib
	@$(CC) -shared -o $@ $< $(LIBS) $(CFLAGS)

$(OBJECT): $(SOURCE) $(HEADER)
	@echo "CC\tshim.o\tshim.c shim.h"
	@$(CC) -c -o $@ $< -Wall -Wextra -Werror $(IDRIS_INCLUDES) $(IDRIS_LDFLAGS)

clean:
	@echo "RM\tlibshim.so shim.o"
	@rm -rf $(SO) $(OBJECT) ../lib
