# Copyright (c) 2013-2014, Loïc Hoguin <essen@ninenines.eu>
# This file is part of erlang.mk and subject to the terms of the ISC License.

.PHONY: distclean-deps distclean-pkg pkg-list pkg-search

# Configuration.

DEPS_DIR ?= $(CURDIR)/deps
export DEPS_DIR

REBAR_DEPS_DIR = $(DEPS_DIR)
export REBAR_DEPS_DIR

ALL_DEPS_DIRS = $(addprefix $(DEPS_DIR)/,$(DEPS))

ifeq ($(filter $(DEPS_DIR),$(subst :, ,$(ERL_LIBS))),)
ifeq ($(ERL_LIBS),)
	ERL_LIBS = $(DEPS_DIR)
else
	ERL_LIBS := $(ERL_LIBS):$(DEPS_DIR)
endif
endif
export ERL_LIBS

PKG_FILE ?= $(CURDIR)/.erlang.mk.packages.v1
export PKG_FILE

PKG_FILE_URL ?= https://raw.githubusercontent.com/extend/erlang.mk/master/packages.v1.tsv

# Core targets.

deps:: $(ALL_DEPS_DIRS)
	@for dep in $(ALL_DEPS_DIRS) ; do \
		if [ -f $$dep/Makefile ] ; then \
			$(MAKE) -C $$dep ; \
		else \
			if [ -f $$dep/rebar.config ] ; then \
				cd $$dep ; ./rebar get-deps compile ; \
			else \
				echo "include $(CURDIR)/erlang.mk" | $(MAKE) -f - -C $$dep ; \
			fi ; \
		fi ; \
	done

distclean:: distclean-deps distclean-pkg

# Deps related targets.

get_pkg_file := wget $(PKG_FILE_URL) -o $(PKG_FILE)

fetch_git = git clone -n -- $(1) $(2)
checkout_git = git checkout -q $(1)
dep[repo_type] = $(if $(findstring 3,$(words $(dep_$(1)))),$(word 1,$(dep_$(1))),git)
dep[repo_url] = $(if $(findstring 3,$(words $(dep_$(1)))),$(word 2,$(dep_$(1))),$(word 1,$(dep_$(1))))
dep[repo_rev] = $(if $(findstring 3,$(words $(dep_$(1)))),$(word 3,$(dep_$(1))),$(word 2,$(dep_$(1))))

define dep_fetch
	@mkdir -p $(DEPS_DIR)
ifeq (,$(findstring pkg://,$(word 1,$(dep_$(1)))))
	@$(call fetch_$(2),$(dep[repo_url]),$(DEPS_DIR)/$(1),$(dep[repo_rev]))
else
	@if [ ! -f $(PKG_FILE) ]; then $(call get_pkg_file); fi ; \
	git clone -n -- `awk 'BEGIN { FS = "\t" }; \
		$$$$1 == "$(subst pkg://,,$(word 1,$(dep_$(1))))" { print $$$$2 }' \
		$(PKG_FILE)` $(DEPS_DIR)/$(1)
endif
	@cd $(DEPS_DIR)/$(1) ; $(call checkout_$(2),$(dep[repo_rev]))
endef

define dep_target
$(info Processing dependency $(1) located at "$(dep_$(1))")
$(DEPS_DIR)/$(1):
	$(call dep_fetch,$(1),$(if $(findstring 3,$(words $(dep_$(1)))),$(word 1,$(dep_$(1))),git))
endef

$(foreach dep,$(DEPS),$(eval $(call dep_target,$(dep))))

distclean-deps:
	$(gen_verbose) rm -rf $(DEPS_DIR)

# Packages related targets.

$(PKG_FILE):
	$(call core_http_get,$(PKG_FILE),$(PKG_FILE_URL))

pkg-list: $(PKG_FILE)
	@cat $(PKG_FILE) | awk 'BEGIN { FS = "\t" }; { print \
		"Name:\t\t" $$1 "\n" \
		"Repository:\t" $$2 "\n" \
		"Website:\t" $$3 "\n" \
		"Description:\t" $$4 "\n" }'

ifdef q
pkg-search: $(PKG_FILE)
	@cat $(PKG_FILE) | grep -i ${q} | awk 'BEGIN { FS = "\t" }; { print \
		"Name:\t\t" $$1 "\n" \
		"Repository:\t" $$2 "\n" \
		"Website:\t" $$3 "\n" \
		"Description:\t" $$4 "\n" }'
else
pkg-search:
	@echo "Usage: make pkg-search q=STRING"
endif

distclean-pkg:
	$(gen_verbose) rm -f $(PKG_FILE)

help::
	@printf "%s\n" "" \
		"Package-related targets:" \
		"  pkg-list              List all known packages" \
		"  pkg-search q=STRING   Search for STRING in the package index"
