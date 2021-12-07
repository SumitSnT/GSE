%==========================================================================
%     CADSAT: Carrier Aggregation in Satellite Communication Networks
%                    Load balancing Scheduler
%==========================================================================
clear;clc;close
addpath(genpath('Aux_Functions'))

% PDUs Generation ---------------------------------------------------------
PDU_number = 100;       % Input:- Number of PDUs
PDU_length = 1400;      % Input:- Size of each PDU in bytes
PDUs = PDU_generator(PDU_number,PDU_length); % Output:- PDUs in cell array format
%==========================================================================

% Scheduler ---------------------------------------------------------------
BW1 = 10;       % Input:- 1st carrier bandwidth in MHz
SNR1 = 5;       % Input:- 1st carrier SNR in dB
FR1 = 0.7;      % Input:- 1st carrier fill rate (between 0 to 1)

BW2 = 10;       % Input:- 2nd carrier bandwidth in MHz
SNR2 = 5;       % Input:- 2nd carrier SNR in dB
FR2 = 0.7;      % Input:- 2nd carrier fill rate

% [S1,S2] = PDU_Scheduler(PDUs,PDU_number,BW1,SNR1,FR1,BW2,SNR2,FR2);   % Output:- Carrier Allocation Sequence
[S1,S2] = PDU_Scheduler(PDUs,BW1,SNR1,FR1,BW2,SNR2,FR2);   % Output:- Carrier Allocation Sequence
%==========================================================================

% Transmitter -------------------------------------------------------------
 transmit_BBF1 = Transmitter(S1,SNR1,FR1);
 transmit_BBF2 = Transmitter(S2,SNR2,FR2);
 
% Receiver ----------------------------------------------------------------
Received_PDU1 = Receiver(transmit_BBF1);
Received_PDU2 = Receiver(transmit_BBF2);

% Checking ----------------------------------------------------------------
R_PDU = [];
for z = 1:size(Received_PDU,1)
    R_PDU(z,:) = cell2mat(Received_PDU(z,2));
    PDUids = bi2de(R_PDU(:,1:8), 'left-msb');
    PDU_rcv = bi2de(reshape(R_PDU(z,:),length(R_PDU)/8,8),'left-msb');
    PDU_rcv = PDU_rcv(2:end);
end
rr = 1;
Received_PDU_order_check = 1;
for jj=9:-1:0
    for ii=1:10
        if PDUids(rr) == Received_PDU_order_check
            rectangle('Position',[ii jj 1 1],'EdgeColor',[0.5 0.5 0.5])
            Received_PDU_order_check = Received_PDU_order_check + 1;
        else
            rectangle('Position',[ii jj 1 1],'FaceColor',[1 1 0],'EdgeColor',[0.5 0.5 0.5])
            Received_PDU_order_check = Received_PDU_order_check + 1;
        end
        if cell2mat(Received_PDU(rr,1)) == 1
            text(ii+0.3,jj+0.5,num2str(PDUids(rr)),'Color','red')
            rr = rr +1;
        else
            text(ii+0.3,jj+0.5,num2str(PDUids(rr)),'Color','blue')
            rr = rr +1;
        end
    end
end
axis('off');

 
