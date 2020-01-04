# SPDX-License-Identifier: FSFAP

INST_DIR ?= inst
SYSTEMD_UNIT_DIR ?= /etc/systemd/system

SQLITE3 = sqlite3

WAIT_MEAN ?= 20.0
WAIT_STDDEV ?= 2.0

INST_DB = $(INST_DIR)/denic-drei.db
INST_SERVICE = $(INST_DIR)/denic-drei.service

EXCLUDES = excludes

.PHONY: all clean install install-scripts uninstall

all: $(INST_DB) $(INST_SERVICE) install-scripts

$(INST_DB): denic-drei.sql
	@mkdir -p $(INST_DIR)
	$(SQLITE3) "$@" < $<
	echo "INSERT INTO settings VALUES ($(WAIT_MEAN), $(WAIT_STDDEV));" | $(SQLITE3) "$@"
	if [ -f "$(EXCLUDES)" ]; then (echo ".mode line"; echo ".import \"$(EXCLUDES)\" excluded") | $(SQLITE3) "$@"; fi

$(INST_SERVICE): denic-drei.service
	@mkdir -p $(INST_DIR)
	sed "s:PLACEHOLDER_PATH:$$(realpath "$(INST_DIR)"):;s:PLACEHOLDER_USER:$$(stat -c %U "$(INST_DB)"):" $< > "$@"

clean:
	rm -rf "$(INST_DIR)"

install-scripts:
	install denic-drei denic-drei-stats "$(INST_DIR)"
	gitver="$$(git describe --all --long 2>/dev/null || echo git)" && sed -i "/GITVERSION/s:GITVERSION:$${gitver##*-}:g" "$(INST_DIR)/denic-drei"

install: all
	install -m 644 "$(INST_SERVICE)" "$(SYSTEMD_UNIT_DIR)"
	if [ "$$(ps -p 1 -o comm=)" = systemd ]; then systemctl --system daemon-reload; fi

uninstall: clean
	rm -f "$(SYSTEMD_UNIT_DIR)/denic-drei.service"
	if [ "$$(ps -p 1 -o comm=)" = systemd ]; then systemctl --system daemon-reload; fi	
