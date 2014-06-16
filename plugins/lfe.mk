LFE_SRC_DIR = $(CURDIR)/src
LFE_TEST_DIR = $(CURDIR)/test
LFEC ?= lfec

ifneq ($(wildcard $(LFE_SRC_DIR)/*.lfe),)
ebin/$(PROJECT).app:: $(wildcard $(LFE_SRC_DIR)/*.lfe)
	$(LFEC) -o ebin $?
endif

ifneq ($(wildcard $(LFE_TEST_DIR)/*.lfe),)
ebin/$(PROJECT).app:: $(wildcard $(LFE_TEST_DIR)/*.lfe)
	$(LFEC) -o ebin $?
endif
