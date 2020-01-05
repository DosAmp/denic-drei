# SPDX-License-Identifier: FSFAP

# make does not support anything with spaces here, so uses of INST_* variables
# are not quoted for the shell either
INST_DIR ?= inst
SYSTEMD_UNIT_DIR ?= /etc/systemd/system
WAIT_MEAN ?= 20.0
WAIT_STDDEV ?= 2.0
EXCLUDES ?= excludes

SQLITE3 = sqlite3

INST_DB = $(INST_DIR)/denic-drei.db
INST_SERVICE = $(INST_DIR)/denic-drei.service
INST_PROGRAM = $(INST_DIR)/denic-drei
INST_PROGRAM_STATS = $(INST_DIR)/denic-drei-stats

.PHONY: all clean install install-scripts install-service uninstall uninstall-service

all: $(INST_DB) $(INST_PROGRAM) $(INST_PROGRAM_STATS)

$(INST_DIR)/:
	mkdir -p $@

# order-only prerequisites only work with GNU Make 3.80+
$(INST_DB): denic-drei.sql | $(INST_DIR)/
	$(SQLITE3) $@ < $<
	echo "INSERT INTO settings VALUES ($(WAIT_MEAN), $(WAIT_STDDEV));" | $(SQLITE3) $@
	if [ -f "$(EXCLUDES)" ]; then (echo ".mode line"; echo '.import "$(EXCLUDES)" excluded') | $(SQLITE3) $@; fi

$(INST_PROGRAM): denic-drei | $(INST_DIR)/
	install $< $(INST_DIR)
	gitver="$$(git describe --all --long 2>/dev/null || echo git)" && sed -i "/GITVERSION/s:GITVERSION:$${gitver##*-}:g" $@

$(INST_PROGRAM_STATS): denic-drei-stats | $(INST_DIR)/
	install $< $(INST_DIR)

# only specific to GNU/systemd
install-service: denic-drei.service
	sed "s:PLACEHOLDER_PATH:$$(realpath $(INST_DIR)):;s:PLACEHOLDER_USER:$$(stat -c %U $(INST_DB)):" $< > "$(SYSTEMD_UNIT_DIR)/$<"
	if [ "$$(ps -p 1 -o comm=)" = systemd ]; then systemctl --system daemon-reload; fi

install: all install-service

uninstall: uninstall-service clean

uninstall-service:
	rm -f "$(SYSTEMD_UNIT_DIR)/denic-drei.service"
	if [ "$$(ps -p 1 -o comm=)" = systemd ]; then systemctl --system daemon-reload; fi

clean:
	rm -rf $(INST_DIR)
