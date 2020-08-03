calling_from_make:
	mix compile

all:
	$(MAKE) -C src all

clean:
	$(MAKE) -C src clean

.PHONY: all clean calling_from_make
