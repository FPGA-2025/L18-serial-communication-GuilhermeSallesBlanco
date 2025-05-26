module transmitter (
    input clk,
    input rstn,
    input start, // Sinal que indica que o transmissor deve começar a enviar dados.
    input [6:0] data_in, // Entrada de 7 bits de dados. Lido quando start fica em nível alto.
    output reg serial_out // Saída serial do transmissor.
);

reg [7:0] data_reg; // Registro para armazenar os dados de entrada

// Definindo estados, um estado para cada bit enviado
localparam IDLE = 4'd0,
           START = 4'd1,
           ENVIA_DADOS = 4'd2, 
           STOP = 4'd3,
           RESET = 4'd4;

reg [3:0] estado, prox_estado;
reg [3:0] contador; // contador para controlar o envio de bits

// Lógica de clock e reset
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        estado <= RESET;
    end else begin
        estado <= prox_estado;
    end

end

// Lógica de transição de estados
always @(estado) begin
    case(estado)
        RESET: begin
            prox_estado = IDLE; // Volta para o estado IDLE após reset
        end
        IDLE: begin
            if(!start) begin
                prox_estado = START;
            end else begin
                prox_estado = IDLE;
            end
        end
        START: begin
            prox_estado = ENVIA_DADOS; // Após o início, vai para o estado de envio de dados
        end
        ENVIA_DADOS: begin
            prox_estado = contador >= 8 ? STOP : ENVIA_DADOS;
        end
        STOP: begin
            prox_estado = IDLE; // Volta para o estado IDLE após enviar todos os bits
        end
        default: begin
            prox_estado = IDLE; // Estado de segurança
        end
    endcase
end

// Lógica de saída serial
always @(posedge clk) begin
    case (estado)
        RESET: begin
            // Inicializa registradores
            data_reg = 8'b00000000;  // Limpa buffer
            serial_out   = 8'b11111111;  // Mantém linha inativa
        end

        IDLE: begin
        end

        START: begin
            contador = 4'b0000;      // Zera contador de bits
            data_reg = {(^data_in), data_in}; // Calcula bit de paridade e armazena dados
            serial_out   = 1'b0;         // Envia bit de start (0)
        end

        ENVIA_DADOS: begin
            contador <= contador+1; // Incrementa contador (usa <= para atribuição não-bloqueante)
                if (contador < 8) begin
                    // Envia bits do buffer sequencialmente
                    serial_out = data_reg[contador];
                end else begin
                    // Todos bits enviados, coloca linha em 1
                    serial_out = 1'b1;
                end
        end

        STOP: begin
                serial_out = 1'b0; 
        end
    endcase
end

endmodule