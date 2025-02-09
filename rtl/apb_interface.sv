interface apb_i();
    logic i_pclk, i_presetn;
    logic i_psel, i_penable, i_pwrite;
    logic [31:0] i_paddr, i_pwdata;
    logic [31:0] o_prdata;
    logic o_pready, o_pslverr;
endinterface
