# The files
FILES		= src/decoder.vhdl \
               src/alu.vhdl \
               src/memory.vhdl \
               src/instr_memory.vhdl \
               src/cpu.vhdl \
               src/registers.vhdl\
               pc/motherboard.vhdl
SIMDIR		= sim
SIMFILES	= test/decoder_tb.vhdl \
           test/mem_tb.vhdl \
           test/instr_memory_tb.vhdl \
           test/cpu_tb.vhdl \
           test/cpu_tb1.vhdl \
           test/beq_tb.vhdl \
           test/bne_tb.vhdl \
           test/blt_tb.vhdl \
           test/bge_tb.vhdl \
           test/forloop_tb.vhdl \
           test/shift_tb.vhdl \
           test/slt_tb.vhdl \
           test/motherboard_tb.vhdl \
           test/pc_tb.vhdl

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
	ghdl -e -o sim/beq_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) beq_tb
	ghdl -e -o sim/bne_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) bne_tb
	ghdl -e -o sim/blt_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) blt_tb
	ghdl -e -o sim/bge_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) bge_tb
	ghdl -e -o sim/forloop_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) forloop_tb
	ghdl -e -o sim/shift_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) shift_tb
	ghdl -e -o sim/slt_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) slt_tb
	ghdl -e -o sim/motherboard_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) motherboard_tb
	ghdl -e -o sim/pc_tb $(GHDL_FLAGS) $(GHDL_WORKDIR) pc_tb
	
run:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) pc_tb --stop-time=250ns --wave=pc2.ghw; \
	cd ..

.PHONY: run_mb
run_mb:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) motherboard_tb --stop-time=250ns --wave=pc.ghw; \
	cd ..

.PHONY: test	
test:
	cd sim; \
	ghdl -r $(GHDL_FLAGS) cpu_tb --stop-time=250ns --wave=cpu_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) cpu_tb1 --stop-time=1500ns --wave=cpu_test.ghw; \
	ghdl -r $(GHDL_FLAGS) beq_tb --stop-time=800ns --wave=beq_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) bne_tb --stop-time=800ns --wave=bne_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) blt_tb --stop-time=800ns --wave=blt_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) bge_tb --stop-time=800ns --wave=bge_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) forloop_tb --stop-time=1300ns --wave=forloop_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) shift_tb --stop-time=450ns --wave=shift_tb.ghw; \
	ghdl -r $(GHDL_FLAGS) slt_tb --stop-time=250ns --wave=slt_tb.ghw; \
	cd ..

view:
	gtkwave sim/cpu_tb.ghw
	
test_view:
	gtkwave sim/cpu_test.ghw

clean:
	$(GHDL_CMD) --clean --workdir=sim
