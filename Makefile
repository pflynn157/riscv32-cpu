# The files
FILES		= src/and.vhdl
SIMDIR		= sim
SIMFILES	= test/and_tb.vhdl

# GHDL
GHDL_CMD	= ghdl
GHDL_FLAGS	= --ieee=synopsys --warn-no-vital-generic
GHDL_WORKDIR = --workdir=sim --work=work
GHDL_STOP	= --stop-time=500ns

# For visualization
VIEW_CMD        = /usr/bin/gtkwave

# The commands
all:
	make compile
	make run

compile:
	mkdir -p sim
	ghdl -a $(GHDL_FLAGS) $(GHDL_WORKDIR) $(FILES)
	ghdl -a $(GHDL_FLAGS) $(GHDL_WORKDIR) $(SIMFILES)
	ghdl -e -o sim/and_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) and_tb

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) and_tb $(GHDL_STOP) --wave=wave.ghw; \
	cd ..

view:
	gtkwave sim/wave.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
