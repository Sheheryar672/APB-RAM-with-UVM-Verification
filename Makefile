FILELIST = filelist.f

$(FILELIST): 
	@echo "Generating filelist.f"
	@find rtl uvm_tb -name "*.sv" > $(FILELIST)
	@echo "Filelist generated"

compile: $(FILELIST)
	@echo "Compiling all files"
	@vlog -work work -sv -f $(FILELIST)

run: compile
	@echo "Running"
	@vsim -voptargs=+acc -c work.apb_tb -do \
	 "add wave -position insertpoint sim:/apb_tb/dut/*; \
	   run -all; quit"

wave: 
	@echo "Displaying waveform"
	@vsim -view vsim.wlf


clean:  
	@rm -rf filelist.f
	@rm -rf work
	@rm -rf transcript
	@rm -rf tr_db.log
	@rm -rf *.vcd
	@rm -rf +acc
	@rm -rd *.wlf
	@rm -rd *.vstf
