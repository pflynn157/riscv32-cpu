# The files
FILES		= src/decoder.vhdl \
               src/alu.vhdl \
               src/memory.vhdl \
               src/instr_memory.vhdl \
               src/cpu.vhdl \
               src/registers.vhdl
SIMDIR		= sim
SIMFILES	= test/decoder_tb.vhdl \
           test/mem_tb.vhdl \
           test/instr_memory_tb.vhdl \
           test/cpu_tb.vhdl \
           test/cpu_tb1.vhdl

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
	ghdl -e -o sim/mem_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) mem_tb
	ghdl -e -o sim/instr_memory_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) instr_memory_tb
	ghdl -e -o sim/cpu_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) cpu_tb
	ghdl -e -o sim/cpu_tb1 $(GHDL_FLAGS) $(GHDL_WORKDIR) cpu_tb1

run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) cpu_tb $(GHDL_STOP) --wave=cpu_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) cpu_tb1 --stop-time=1000ns --wave=cpu_test.ghw; \
	cd ..

view:
	gtkwave sim/cpu_tb.ghw
	
test_view:
	gtkwave sim/cpu_test.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
