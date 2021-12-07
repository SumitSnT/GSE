function [S1,S2] = PDU_Scheduler(PDUs,BW1,SNR1,FR1,BW2,SNR2,FR2)
% This function calculates the load-balancing factor and the allocation sequence
addpath(genpath('Aux_Functions'))
load('allocation_sequence')

PDU_number = length(PDUs);
[SE1,~,CR1] = loglike_coderate2(SNR1);      % Carrier 1
T1 = (64800*CR1/SE1)/(BW1*1e6);
C1 = 64800*CR1/T1;

[SE2,~,CR2] = loglike_coderate2(SNR2);      % Carrier 2
T2 = (64800*CR2/SE2)/(BW2*1e6);
C2 = 64800*CR2/T2;
alpha = round((C2*FR2)/(C1*FR1),2);

if alpha < 0.2
    errordlg('The considered carriers are unbalanced, CA cannot be applied','Alert Message');
    return
end
A = allocation_sequence{([allocation_sequence{:,1}]==alpha),2};   % recall allocation sequence
A = A(mod(0:PDU_number-1,numel(A))+1);          % adjust allocation sequence length

S1=[];S2=[];
for p=1:PDU_number
    if A(p) == 1 % 1st Carrier
        S1 = [S1;cell2mat(PDUs{p})];
    elseif A(p) == 2 % Second Carrier
        S2 = [S2;cell2mat(PDUs{p})];
    end
end