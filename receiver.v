module receiver (
    input clk,
    input rstn,
    output ready, // Quando o receptor estiver com todos os dados da palavra de 7 bits, ele deve sinalizar isso com ready
    output [6:0] data_out, // Saída de 7 bits mostrando os dados lidos. Só é valida quando ready estiver em nível alto
    output parity_ok_n, // Saída que indica que a paridade par dos 8 bits recebidos está ok. Nível baixo significa paridade ok
    input serial_in // Entrada de dados serial.
);

reg [3:0] counter;
reg [7:0] data_buffer; 
reg r_dados;

// Criando registradores internos
reg rready;
reg [6:0] rdata_out;
reg rparity_ok_n;

always @(posedge clk or negedge rstn) begin
    if(!rstn) begin
        counter <= 0;
        data_buffer <= 0;
        r_dados <= 0;
        rready <= 0;
        rdata_out <= 0;
        rparity_ok_n <= 1;
    end else begin
        rready = 0;
        if(!r_dados) begin
            if(!serial_in) begin
                counter <= 0;
                r_dados <= 1; // Inicia a recepção de dados
            end
        end else begin
            counter <= counter + 1;
            if(counter < 8) begin
                data_buffer = {serial_in, data_buffer[7:1]}; // Desloca os dados para a esquerda e adiciona o novo bit
            end else if(counter == 8) begin
                rdata_out <= data_buffer[6:0]; // Armazena os 7 bits de dados
                rparity_ok_n = ^{data_buffer[7:0]}; // Calcula a paridade dos 8 bits recebidos
                rready <= 1; // Indica que os dados estão prontos
                r_dados <= 0; // Reseta o estado de dados recebidos
            end
        end
    end
end

assign ready = rready;
assign data_out = rdata_out;
assign parity_ok_n = rparity_ok_n;

endmodule