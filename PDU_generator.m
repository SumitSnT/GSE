function [PDUs] = PDU_generator(PDU_number,PDU_length)
%--------------------------------------------------------------------------
PDUs = {};
for p=1:PDU_number
    PDU_decimal = randi([0,255],1,PDU_length-1);
    PDU = [p,PDU_decimal]; % PDU header + data
    PDU_binary = de2bi(PDU,8,'left-msb');
    PDU_binary = PDU_binary';
    PDU_data = reshape(PDU_binary,(PDU_length)*8,1);
    PDUs{p} = {PDU_data'};
end