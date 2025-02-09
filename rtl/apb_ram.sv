module apb_ram(
    input  logic i_pclk, i_presetn,
    input  logic i_psel, i_penable, i_pwrite,
    input  logic [31:0] i_paddr, i_pwdata,
    output logic [31:0] o_prdata,
    output logic o_pready, o_pslverr
);

logic [31:0] mem [32];

typedef enum bit [1:0] {idle, setup, access, complete_tx} state_ty;
state_ty state = idle;

always @(posedge i_pclk) begin
    if(i_presetn == 1'b0) begin /// Active low reset
        state   <= idle;
        o_prdata  <= 32'h00000000;
        o_pready  <= 1'b0;
        o_pslverr <= 1'b0;

        for(int i; i < 32; i++) begin
            mem[i] <= '0;
        end
    end 

    else begin
        case(state)
            idle: begin
                o_prdata  <= 32'h00000000;
                o_pready  <= 1'b0;
                o_pslverr <= 1'b0;
                state   <= setup;
            end   

            setup: begin    /// start of a transaction
                if (i_psel == 1)
                    state <= access;
                else
                    state <= setup;
            end

            access: begin
                if(i_pwrite && i_penable) begin     /// write op
                    if(i_paddr < 32) begin
                        mem[i_paddr] <= i_pwdata;
                        state <= complete_tx;
                        o_pready  <= 1'b1;
                        o_pslverr <= 1'b0;
                    end

                    else begin
                        state <= complete_tx;
                        o_pready  <= 1'b1;
                        o_pslverr <= 1'b1;
                    end
                end

                else if (!i_pwrite && i_penable) begin  /// read op
                    if (i_paddr < 32) begin
                        o_prdata <= mem[i_paddr];
                        state <= complete_tx;
                        o_pready  <= 1'b1;
                        o_pslverr <= 1'b0;
                    end

                    else begin
                        o_prdata <= 32'hxxxxxxxx;
                        state <= complete_tx;
                        o_pready  <= 1'b1;
                        o_pslverr <= 1'b1;
                    end
                end
            end

            complete_tx: begin
                state <= setup;
                o_pready <= 1'b0;
                o_pslverr <= 1'b0;
            end

            default: state <= idle;
        endcase
    end

end

endmodule