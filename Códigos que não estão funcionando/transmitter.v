module transmitter (
    input clk,
    input rstn,
    input start, // Sinal que indica que o transmissor deve começar a enviar os dados. No ciclo seguinte à sinalização, a linha deve estar em nível alto.
    input [6:0] data_in, // Entrada de 7 bits com os dados a serem enviados. Ela é lida no ciclo que start fica em nível alto.
    output reg serial_out // Saída serial por onde os dados serão enviados.
);

// Barramento/linha de dados em nível alto.
// Quando a comunicação vai iniciar, o transmissor coloca o barramento em nível baixo e no ciclo seguinte começa a enviar os bits.
// São enviado 8 bits, sendo que o oitavo bit é de paridade, do tipo par.
// Ao final da transmissão, a linha deve voltar a descansar em nível alto.

// Definindo estados
localparam RESET                = 3'd0;
localparam AGUARDA_START        = 3'd1;
localparam START                = 3'd2;
localparam ENVIA_DADOS          = 3'd3;
localparam FINALIZA_ENVIO_DADOS = 3'd4;

wire bit_parity = ~^data_in; // Calcula a paridade par dos 7 bits de data_in
reg [2:0] estado, prox_estado; // Estado atual do transmissor
reg [3:0] counter; // Contador para controlar o número de bits enviados
reg [7:0] buffer; // Buffer para armazenar os 8 bits a serem enviados, incluindo o bit de paridade

// Lógica de clock e mudança de estado
always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        estado = RESET;
    end else begin
        estado = prox_estado;
    end
end

// Lógica de transição de estados
always @(*) begin
    case(estado)
        RESET: begin
            prox_estado = AGUARDA_START;
        end
        AGUARDA_START: begin
            prox_estado = (!start ? START : AGUARDA_START);
        end
        START: begin
            prox_estado = ENVIA_DADOS; // Transição para enviar os dados
        end
        ENVIA_DADOS: begin
            prox_estado = counter >= 8 ? FINALIZA_ENVIO_DADOS : ENVIA_DADOS;
        end
        FINALIZA_ENVIO_DADOS: begin
            prox_estado = AGUARDA_START;
        end
    endcase
end

// Saída
always @(posedge clk) begin
    case(estado)
        RESET: begin
            serial_out = 1; // Linha em nível alto
            buffer = 8'b0; // Limpa o buffer
        end
        START: begin
            counter = 4'b0000; // Reseta o contador
            serial_out = 1'b0; // Linha em nível baixo para sinalizar o início da transmissão
            buffer = {(^data_in), data_in}; // Prepara o buffer com os dados e o bit de paridade
        end
        ENVIA_DADOS: begin
            counter <= counter+1;
            if(counter < 8) begin
                serial_out = buffer[counter]; // Envia o bit atual do buffer
            end else begin
                serial_out = 1; // Linha em nível alto após enviar todos os bits
            end
        end
        FINALIZA_ENVIO_DADOS: begin
            serial_out = 1'b1; // Linha em nível alto após a transmissão
        end
    endcase
end

endmodule