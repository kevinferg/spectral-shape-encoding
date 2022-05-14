# Makefile
# make
# make clean
# make bin/main.exe
# ... on Windows using mingw: 'mingw32-make' instead of 'make'

# Directory names (TSTDIR & BINDIR are also subdirectories of INCDIR)
OBJDIR = obj
INCDIR = include
SRCDIR = src
BINDIR = bin

# Final executable names (& corresponding sources)
MAIN = calc_sdf

# For Windows:
EXE = .exe
VPATH = $(SRCDIR):$(OBJDIR)

# Change 'del' to 'rm' on non-Windows systems:
RM = del
CC = gcc
INC_LOCATIONS = $(INCDIR)
INC_FLAGS = $(addprefix -I,$(INC_LOCATIONS))
CFLAGS =  $(INC_FLAGS) -MMD -MP

srcs = $(notdir $(wildcard $(SRCDIR)/*.c))

deps = $(srcs:.c=.d) $(tsts:.c=.d)

src_objs = $(addprefix $(OBJDIR)/,$(srcs:.c=.o))


-include $(deps)

all: $(BINDIR)/$(MAIN)$(EXE)

$(BINDIR)/$(MAIN)$(EXE): $(src_objs) | silent
	$(CC) $^ -o $@ -s


$(OBJDIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $^ -o $@

.PHONY: clean all

silent:
	@:

# Change \\ to / on non-Windows systems:
clean:
	$(RM) /Q $(OBJDIR)\\* $(BINDIR)\\*

