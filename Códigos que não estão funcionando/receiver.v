module receiver (
    input clk,
    input rstn,
    output reg ready,
    output reg [6:0] data_out,
    output reg parity_ok_n,
    input serial_in
);

parameter IDLE      = 2'b00,
          START     = 2'b01,
          RECEBENDO = 2'b10,
          FIM       = 2'b11;

reg [1:0]  estado, prox_estado;
reg [3:0]  counter;
reg [7:0]  buffer;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        estado       <= IDLE;
        counter      <= 0;
        buffer       <= 0;
        ready        <= 0;
        data_out     <= 0;
        parity_ok_n  <= 1;
    end else begin
        estado <= prox_estado;
    end
end

// FSM de transição
always @(*) begin
    case (estado)
        IDLE:      prox_estado = (serial_in==0) ? START     : IDLE;
        START:     prox_estado = RECEBENDO;
        RECEBENDO: prox_estado = (counter < 9) ? RECEBENDO : FIM;  // 1 ciclo de delay + 8 bits
        FIM:       prox_estado = IDLE;
        default:   prox_estado = IDLE;
    endcase
end

// Lógica de captura
always @(posedge clk) begin
    case (estado)
        IDLE: begin
            counter <= 0;
            ready   <= 0;
        end

        START: begin
            counter <= 0;   // prepara delay
        end

        RECEBENDO: begin
            counter <= counter + 1;
            // só grava a partir do segundo ciclo (counter==1)
            if (counter >= 1 && counter <= 8) begin
                buffer[counter-1] <= serial_in;
            end
        end

        FIM: begin
            data_out     <= buffer[6:0];
            parity_ok_n  <= ^buffer; // XOR de todos os 8 bits: 0 = par
            ready        <= 1;
        end
    endcase
end

endmodule
