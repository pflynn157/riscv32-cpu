# The files
FILES		= src/decoder.vhdl
SIMDIR		= sim
SIMFILES	= test/decoder_tb.vhdl

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
	ghdl -e -o sim/decoder_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) decoder_tb

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) decoder_tb $(GHDL_STOP) --wave=decoder.ghw; \
	cd ..

view:
	gtkwave sim/decoder.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
