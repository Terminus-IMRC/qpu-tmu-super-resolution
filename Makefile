all:

TARGET := sr
SRCS := driver.c
DEPS := $(SRCS:%.c=%.c.d)
OBJS := $(SRCS:%.c=%.c.o)
QASM4S := main.qasm4
QASMS := $(QASM4S:%.qasm4=%.qasm4.qasm)
QBINS := $(QASMS:%.qasm=%.qasm.bin)
QHEXS := $(QBINS:%.bin=%.bin.hex)
ALLDEPS = $(MAKEFILE_LIST_SANS_DEPS)
CFLAGS_LOCAL := -Wall -Wextra -O0 -g
LDLIBS_LOCAL := -lvc4vec

# $(eval $(call dep-on-c, dep, c-source))
define dep-on-c
 $(2:%.c=%.c.d) $(2:%.c=%.c.o): $1
endef

# $(eval $(call qasm4-dep-on-c, qasm4-source, c-source))
define qasm4-dep-on-c
 $(call dep-on-c, $(1:%.qasm4=%.qasm4.qasm), $2)
 $(call dep-on-c, $(1:%.qasm4=%.qasm4.qasm.bin), $2)
 $(call dep-on-c, $(1:%.qasm4=%.qasm4.qasm.bin.hex), $2)
endef

$(eval $(call qasm4-dep-on-c, main.qasm4, driver.c))

CC := gcc
QBIN2HEX := qbin2hex
QTC := qtc
M4 := m4
RM := rm -f

VALID_MAKECMDGOALS := all $(TARGET) %.c.d %.c.o clean
NONEED_DEP_MAKECMDGOALS := clean

EXTRA_MAKECMDGOALS := $(filter-out $(VALID_MAKECMDGOALS), $(MAKECMDGOALS))
ifneq '$(EXTRA_MAKECMDGOALS)' ''
  $(error No rule to make target `$(firstword $(EXTRA_MAKECMDGOALS))')
else
  ifeq '$(filter-out $(NONEED_DEP_MAKECMDGOALS), $(MAKECMDGOALS))' '$(MAKECMDGOALS)'
    sinclude $(DEPS)
	else
    ifneq '$(words $(MAKECMDGOALS))' '1'
      $(error Specify only one target if you want to make target which needs no source code dependency)
    endif
  endif
endif

MAKEFILE_LIST_SANS_DEPS := $(filter-out %.c.d, $(MAKEFILE_LIST))

LINK.o = $(CC) $(CFLAGS) $(CFLAGS_LOCAL) $(EXTRACFLAGS) $(CPPFLAGS) $(CPPFLAGS_LOCAL) $(EXTRACPPFLAGS) $(TARGET_ARCH)
COMPILE.c = $(CC) $(CFLAGS) $(CFLAGS_LOCAL) $(EXTRACFLAGS) $(CPPFLAGS) $(CPPFLAGS_LOCAL) $(EXTRACPPFLAGS) $(TARGET_ARCH) -c
COMPILE.d = $(CC) $(CFLAGS) $(CFLAGS_LOCAL) $(EXTRACFLAGS) $(CPPFLAGS) $(CPPFLAGS_LOCAL) $(EXTRACPPFLAGS) $(TARGET_ARCH) -M -MP -MT $<.o -MF $@

all: $(TARGET)

$(TARGET): $(OBJS) $(ALLDEPS)
	$(LINK.o) $(OUTPUT_OPTION) $(OBJS) $(LOADLIBES) $(LDLIBS) $(LDLIBS_LOCAL)

%.c.o: %.c $(ALLDEPS)
	$(COMPILE.c) $(OUTPUT_OPTION) $<

%.c.d: %.c $(ALLDEPS)
	$(COMPILE.d) $<

%.qasm4.qasm.bin.hex: %.qasm4.qasm.bin $(ALLDEPS)
	$(QBIN2HEX) <$< >$@

%.qasm4.qasm.bin: %.qasm4.qasm $(ALLDEPS)
	$(QTC) <$< >$@

%.qasm4.qasm: %.qasm4 $(ALLDEPS)
	$(M4) <$< >$@

.PHONY: clean
clean:
	$(RM) $(TARGET)
	$(RM) $(OBJS)
	$(RM) $(DEPS)
	$(RM) $(QHEXS)
	$(RM) $(QBINS)
	$(RM) $(QASMS)
