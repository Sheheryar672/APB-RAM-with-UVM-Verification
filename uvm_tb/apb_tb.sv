`include "uvm_macros.svh"
import uvm_pkg::*;

//////////////////////////////////////////////////////////////////
class apb_config extends uvm_object;
    `uvm_object_utils(apb_config)

    function new (string inst = "apb_config");
        super.new(inst);
    endfunction

    uvm_active_passive_enum is_active = UVM_ACTIVE;

endclass : apb_config

//////////////////////////////////////////////////////////////////
typedef enum bit [1:0] {read, writed, rst} op_mode;

//////////////////////////////////////////////////////////////////
class transaction extends uvm_sequence_item;
    
    rand op_mode op;
         logic i_pwrite;
    rand logic [31:0] i_paddr; 
    rand logic [31:0] i_pwdata;
    logic [31:0] o_prdata;
    logic o_pready, o_pslverr;

    `uvm_object_utils_begin(transaction);
        `uvm_field_int(i_pwrite, UVM_ALL_ON);
        `uvm_field_int(i_paddr, UVM_ALL_ON);
        `uvm_field_int(i_pwdata, UVM_ALL_ON);
        `uvm_field_int(o_prdata, UVM_ALL_ON);
        `uvm_field_int(o_pready, UVM_ALL_ON);
        `uvm_field_int(o_pslverr, UVM_ALL_ON);
        `uvm_field_enum(op_mode, op, UVM_DEFAULT);
    `uvm_object_utils_end
    
    constraint addr_c { i_paddr < 32;}
    constraint addr_err_c { i_paddr >= 32;}

    function new (input string inst = "transaction");
        super.new(inst);
    endfunction

endclass : transaction

/////////////////////////////////////////// writed seq
class write_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_seq)

    transaction tr;

    function new (string inst = "write_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);        
        end
        unlock(m_sequencer);
    endtask

endclass : write_seq

///////////////////////////////////////// read seq
class read_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(read_seq)

    transaction tr;

    function new (string inst = "read_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);        
        end
        unlock(m_sequencer);
    endtask

endclass : read_seq

//////////////////////////////////////// read after writed seq
class write_read_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_read_seq)

    transaction tr;

    function new (string inst = "write_read_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);        

            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);        
        end
        unlock(m_sequencer);
    endtask

endclass : write_read_seq


////////////////////////////////////////// bulk writed and bulk read
class writeb_readb_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(writeb_readb_seq)

    transaction tr;

    function new (string inst = "writeb_readb_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);        
        end

        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(1);
            tr.addr_err_c.constraint_mode(0);

            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);        
        end
        unlock(m_sequencer);
    endtask

endclass : writeb_readb_seq

/////////////////////////////////////////// writed with err seq
class write_err_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(write_err_seq)

    transaction tr;

    function new (string inst = "write_err_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(0);
            tr.addr_err_c.constraint_mode(1);

            start_item(tr);
            assert(tr.randomize);
            tr.op = writed;
            finish_item(tr);        
        end
        unlock(m_sequencer);
    endtask

endclass : write_err_seq

///////////////////////////////////////// read with error seq
class read_err_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(read_err_seq)

    transaction tr;

    function new (string inst = "read_err_seq");
        super.new(inst);
    endfunction

    virtual task body();
        lock(m_sequencer);
        repeat(15) begin
            tr = transaction::type_id::create("tr");
            tr.addr_c.constraint_mode(0);
            tr.addr_err_c.constraint_mode(1);

            start_item(tr);
            assert(tr.randomize);
            tr.op = read;
            finish_item(tr);        
        end
        unlock(m_sequencer);
    endtask

endclass : read_err_seq

//////////////////////////////////////////////////////////////////
class driver extends uvm_driver #(transaction);
    `uvm_component_utils(driver)

    transaction tr;
    virtual apb_i vif;

    function new (string inst = "driver", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        tr = transaction::type_id::create("tr");

        if(!uvm_config_db #(virtual apb_i) :: get (this, "", "vif", vif))
            `uvm_error("DRV", "Unable to access the interface!!!");
    endfunction

    task reset_dut();
        repeat (5) begin
            vif.i_presetn <= 1'b0;  /// active low reset
            vif.i_paddr <= 'h0;
            vif.i_pwdata <= 'h0;
            vif.i_pwrite <= 1'b0;
            vif.i_psel <= 1'b0;
            vif.i_penable <= 1'b0;
            `uvm_info("DRV", "System Reset: Start of Simulation", UVM_NONE);
            @(posedge vif.i_pclk);
        end
    endtask

    task drive();
        reset_dut();

        forever begin
            seq_item_port.get_next_item(tr);

                if(tr.op == rst) begin
                    vif.i_presetn <= 1'b0;
                    vif.i_paddr <= 'h0;
                    vif.i_pwdata <= 'h0;
                    vif.i_pwrite <= 1'b0;
                    vif.i_psel <= 1'b0;
                    vif.i_penable <= 1'b0;
                    @(posedge vif.i_pclk);
                    `uvm_info("DRV", "System reset", UVM_NONE);
                end

                else if (tr.op == writed) begin
                    vif.i_presetn <= 1'b1;
                    vif.i_psel <= 1'b1;
                    vif.i_paddr <= tr.i_paddr;
                    vif.i_pwdata <= tr.i_pwdata;
                    vif.i_pwrite <= 1'b1;
                    @(posedge vif.i_pclk);
                    vif.i_penable <= 1'b1;
                    `uvm_info("DRV", $sformatf("mode: %0s, addr: %0d, wdata: %0d, rdata: %0d, slverr: %0d", tr.op.name(), tr.i_paddr, tr.i_pwdata, tr.o_prdata, tr.o_pslverr),UVM_NONE);
                    @(posedge vif.o_pready);
                    vif.i_penable <= 1'b0;
                    tr.o_pslverr = vif.o_pslverr;
                end

                else if (tr.op == read) begin
                    vif.i_presetn <= 1'b1;
                    vif.i_psel <= 1'b1;
                    vif.i_paddr <= tr.i_paddr;
                    vif.i_pwdata <= tr.i_pwdata;
                    vif.i_pwrite <= 1'b0;
                    @(posedge vif.i_pclk);
                    vif.i_penable <= 1'b1;
                    `uvm_info("DRV", $sformatf("mode: %0s, addr: %0d, wdata: %0d, rdata: %0d, slverr: %0d", tr.op.name(), tr.i_paddr, tr.i_pwdata, tr.o_prdata, tr.o_pslverr),UVM_NONE);
                    @(posedge vif.o_pready);
                    vif.i_penable <= 1'b0;
                    tr.o_prdata  = vif.o_prdata;
                    tr.o_pslverr = vif.o_pslverr;                    
                end

            seq_item_port.item_done();
        end
    endtask

    virtual task run_phase(uvm_phase phase);
        drive();
    endtask

endclass : driver

///////////////////////////////////////////////////////////////////
class mon extends uvm_monitor;
    `uvm_component_utils(mon)

    transaction tr;
    uvm_analysis_port #(transaction) send;
    virtual apb_i vif;

    function new (string inst = "mon", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        tr = transaction::type_id::create("tr");
        send = new("send", this);

        if(!uvm_config_db #(virtual apb_i) :: get (this, "", "vif", vif))
        `uvm_error("MON", "Unable to access the interface!!!");
    endfunction

    virtual task run_phase (uvm_phase phase);
        forever begin
            @(posedge vif.i_pclk);
            
            if(!vif.i_presetn) begin    /// reset
                tr.op = rst;
                `uvm_info("MON", "System Reset Detected", UVM_NONE);
                send.write(tr);
            end

            else if (vif.i_presetn && vif.i_pwrite) begin    /// write
                @(posedge vif.o_pready);
                tr.op = writed;
                tr.i_pwdata = vif.i_pwdata;
                tr.i_paddr = vif.i_paddr;
                tr.o_pslverr = vif.o_pslverr;
                `uvm_info("MON", $sformatf("DATA WRITE addr: %0d, wdata: %0d, slv_err: %0d", tr.i_paddr, tr.i_pwdata, tr.o_pslverr), UVM_NONE);
                send.write(tr);
            end

            else if (vif.i_presetn && !vif.i_pwrite) begin   /// read
                @(posedge vif.o_pready);
                tr.op = read;
                tr.o_prdata = vif.o_prdata;
                tr.i_paddr = vif.i_paddr;
                tr.o_pslverr = vif.o_pslverr;
                `uvm_info("MON", $sformatf("DATA READ addr: %0d, rdata: %0d, slv_err: %0d", tr.i_paddr, tr.o_prdata, tr.o_pslverr), UVM_NONE);
                send.write(tr);
            end
        end
    endtask

endclass : mon

///////////////////////////////////////////////////////////////////
class sco extends uvm_scoreboard;
    `uvm_component_utils(sco)

    uvm_analysis_imp #(transaction, sco) recv;
    bit [31:0] mem [32] = '{default:0};
    bit [31:0] addr = 0;
    bit [31:0] rdata = 0;

    integer pass = 0, fail = 0, slverr = 0;

    function new (string inst = "sco", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        recv = new("recv", this);
    endfunction

    virtual function void write (transaction tr);
        if(tr.op == rst) begin
            `uvm_info("SCO", "System Reset Detected",  UVM_NONE);
        end

        else if (tr.op == writed) begin

            if(tr.o_pslverr) begin
                `uvm_info("SCO", "SLV error during write op!!!", UVM_NONE);
                slverr++;
            end

            else begin
                mem[tr.i_paddr] = tr.i_pwdata;
                `uvm_info("SCO", $sformatf("Data WRITE OP --> addr: %0d, i_pwdata: %0d, mem_data:%0d", tr.i_paddr, tr.i_pwdata, mem[tr.i_paddr]), UVM_NONE);
            end
        
        end

        else if (tr.op == read) begin
            
            if(tr.o_pslverr) begin
                `uvm_info("SCO", "SLV error during read op!!!", UVM_NONE);
                slverr++;
            end
            
            else begin
                rdata = mem[tr.i_paddr];

                if (rdata == tr.o_prdata) begin
                    `uvm_info("SCO", $sformatf("DATA MATCHED --> addr: %0d, o_prdata: %0d", tr.i_paddr, tr.o_prdata), UVM_NONE);
                    pass++;
                end

                else begin  
                    `uvm_info("SCO", $sformatf("DATA MISMATCH FOUND!!! --> addr: %0d, o_prdata: %0d, rdata_mem: %0d", tr.i_paddr, tr.o_prdata, rdata), UVM_NONE); 
                    fail++;
                end
            end
        end

        $display("---------------------------------------------------------");
    endfunction

endclass : sco


////////////////////////////////////////////////////////////////////
class agent extends uvm_agent;
    `uvm_component_utils(agent)

    uvm_sequencer #(transaction) seqr;
    driver d;
    mon m;
    apb_config cfg;

    function new (string inst = "agent", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        m = mon::type_id::create("m", this);
        cfg = apb_config::type_id::create("cfg");
        
        if(cfg.is_active == UVM_ACTIVE) begin
            seqr = uvm_sequencer #(transaction)::type_id::create("seqr", this);
            d = driver::type_id::create("d", this);
        end

    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if(cfg.is_active == UVM_ACTIVE)
            d.seq_item_port.connect(seqr.seq_item_export);
    endfunction

endclass : agent

/////////////////////////////////////////////////////////////////////
class env extends uvm_env;
    `uvm_component_utils(env)

    agent a;
    sco s;

    function new (string inst = "env", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        a = agent::type_id::create("a", this);
        s = sco::type_id::create("s", this);
    endfunction

    virtual function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        a.m.send.connect(s.recv);
    endfunction

endclass : env

////////////////////////////////////////////////////////////////////
class test extends uvm_test;
    `uvm_component_utils(test)

    env e;
    write_seq w;
    read_seq r;
    write_read_seq wr; 
    writeb_readb_seq wb_rb;
    write_err_seq w_err;
    read_err_seq r_err;

    function new (string inst = "test", uvm_component parent = null);
        super.new(inst, parent);
    endfunction

    virtual function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        
        e = env::type_id::create("e", this);
        w  = write_seq::type_id::create("w");
        r  = read_seq::type_id::create("r");
        wr  = write_read_seq::type_id::create("wr");
        wb_rb  = writeb_readb_seq::type_id::create("wb_rb");
        w_err  = write_err_seq::type_id::create("w_err");
        r_err  = read_err_seq::type_id::create("r_err");  
    endfunction

    virtual task run_phase (uvm_phase phase);
        phase.raise_objection(this);
            
            w.start(e.a.seqr);
            r.start(e.a.seqr);
            wr.start(e.a.seqr);
            wb_rb.start(e.a.seqr);
            w_err.start(e.a.seqr);
            r_err.start(e.a.seqr);

            $display("test passed: %0d, test_failed: %0d, slverr: %0d", e.s.pass, e.s.fail, e.s.slverr);
            phase.phase_done.set_drain_time(this, 10ns);
        phase.drop_objection(this);
    endtask

endclass : test

///////////////////////////////////////////////////////////////////
module apb_tb;
    
    apb_i vif();

    apb_ram dut (vif.i_pclk, vif.i_presetn, vif.i_psel, vif.i_penable, vif.i_pwrite, vif.i_paddr, vif.i_pwdata, vif.o_prdata, vif.o_pready, vif.o_pslverr);

    initial begin
        vif.i_pclk <= 0;
    end

    always #10 vif.i_pclk <= ~vif.i_pclk;

    initial begin
        uvm_config_db #(virtual apb_i) :: set(null, "*", "vif", vif);
        run_test("test");
    end

endmodule
