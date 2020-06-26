.PHONY: all setup clean run

BASETEST=../TEST-60-BONDBRIDGEVLANIFCFG

all:
	@$(MAKE) SN=1 -s --no-print-directory -C $(BASETEST) all
setup:
	@$(MAKE) SN=1 -s --no-print-directory -C $(BASETEST) setup
clean:
	@$(MAKE) SN=1 -s --no-print-directory -C $(BASETEST) clean
run:
	@$(MAKE) SN=1 -s --no-print-directory -C $(BASETEST) run
