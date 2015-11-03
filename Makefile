
LMP=lmp_mpi
PY=python -u
RUN=test

RATE=1.0
SITES=1
TH=10
FUNC=5
CHAIN_N=1000
CHAIN_STEPS_LAMMPS=1000000
CHAIN_STEPS_ESPP=500
CHAIN_LOOPS_ESPP=4000

CHAIN_LAMMPS=simu_chain_lammps_K$(RATE)_TH$(TH)_S$(SITES)_N$(CHAIN_N)
EPOXY_LAMMPS=simu_epoxy_lammps_K$(RATE)_TH$(TH)_F$(FUNC)
CHAIN_ESPP=simu_chain_espp_K$(RATE)_TH$(TH)_S$(SITES)_N$(CHAIN_N)
EPOXY_ESPP=simu_epoxy_espp_K$(RATE)_TH$(TH)_F$(FUNC)

LAMMPS_CHAIN_FILE=in.chain

mirrorlj.txt: code/write_tabulated_potential.py
	python $< > $@

$(CHAIN_LAMMPS)_%/log.lammps $(CHAIN_LAMMPS)_%/dump_3d.h5: mirrorlj.txt code/$(LAMMPS_CHAIN_FILE)
	@mkdir -p $(CHAIN_LAMMPS)_$*
	VSEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	CSEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	ISEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	A1SEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	A4SEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	(cd $(CHAIN_LAMMPS)_$*; $(LMP) -i ../code/$(LAMMPS_CHAIN_FILE) -var vseed $${VSEED} -var cseed $${CSEED} \
	-var a1seed $${A1SEED} -var a4seed $${A4SEED} \
	-var iseed $${ISEED} -var rate $(RATE) -var sites $(SITES) -var theta $(TH) -var N $(CHAIN_N) \
	-var steps $(CHAIN_STEPS_LAMMPS) > out)

chain_lammps: $(CHAIN_LAMMPS)_$(RUN)/log.lammps $(CHAIN_LAMMPS)_$(RUN)/dump_3d.h5

$(CHAIN_ESPP)_%/log.espp $(CHAIN_ESPP)_%/dump.h5: code/chain_run.py code/chain_h5md.py code/chain_setup.py
	@mkdir -p $(CHAIN_ESPP)_$*
	SEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	(cd $(CHAIN_ESPP)_$*; $(PY) ../code/chain_run.py $(CHAIN_N) --seed $${SEED} --rate $(RATE) \
	 --interval $(TH) --sites $(SITES) --steps $(CHAIN_STEPS_ESPP) --dt 0.0025 --loops $(CHAIN_LOOPS_ESPP) \
	--file dump.h5 --dump-interval 500 > log.espp)

$(CHAIN_ESPP)_%/log_gr.espp $(CHAIN_ESPP)_%/dump_gr.h5: code/chain_run_gr.py code/chain_h5md.py code/chain_setup.py
	@mkdir -p $(CHAIN_ESPP)_$*
	SEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	(cd $(CHAIN_ESPP)_$*; $(PY) ../code/chain_run_gr.py $(CHAIN_N) --seed $${SEED} --rate $(RATE) \
	 --interval $(TH) --sites $(SITES) --steps $(CHAIN_STEPS_ESPP) --dt 0.0025 --loops 400 \
	--file dump.h5 --dump-interval 500 > log.espp)

chain_espp: $(CHAIN_ESPP)_$(RUN)/log.espp $(CHAIN_ESPP)_$(RUN)/dump.h5

chain_espp_gr: $(CHAIN_ESPP)_$(RUN)/log_gr.espp $(CHAIN_ESPP)_$(RUN)/dump_gr.h5

$(EPOXY_LAMMPS)_%/log.lammps $(EPOXY_LAMMPS)_%/nb.txt.gz: mirrorlj.txt code/in.epoxy
	@mkdir -p $(EPOXY_LAMMPS)_$*
	ASEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	VSEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	ESEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	(cd $(EPOXY_LAMMPS)_$*; $(LMP) -i ../code/in.epoxy -var vseed $${VSEED} -var aseed $${ASEED} \
	-var eseed $${ESEED} -var rate $(RATE) -var theta $(TH) -var func $(FUNC) > out)

epoxy_lammps: $(EPOXY_LAMMPS)_$(RUN)/log.lammps $(EPOXY_LAMMPS)_$(RUN)/nb.txt.gz

$(EPOXY_ESPP)_%/log.espp $(EPOXY_ESPP)_%/dump.h5: code/epoxy_run.py code/epoxy_h5md.py code/epoxy_setup.py
	@mkdir -p $(EPOXY_ESPP)_$*
	SEED=$(shell head --bytes=2 /dev/urandom | od -t u2 | head -n1 | awk '{print $$2}') ; \
	(cd $(EPOXY_ESPP)_$*; $(PY) ../code/epoxy_run.py 2500 1000 --seed $${SEED} --rate $(RATE) \
	 --interval $(TH) --file dump.h5 --dump-interval 1000 --loops 2500 --functionality $(FUNC) > log.espp)

epoxy_espp: $(EPOXY_ESPP)_$(RUN)/log.espp $(EPOXY_ESPP)_$(RUN)/dump.h5
