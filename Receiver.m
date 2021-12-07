function Received_PDU = Receiver(transmit_BBF, usefull_bits)

% Receiver ----------------------------------------------------------------
reconstructed_PDU1 = [];
reconstructed_PDU2 = [];
reconstructionTimeC1 = [];
reconstructionTimeC2 = [];
totalreconstructed_PDU1 = [];
totalreconstructed_PDU2 = [];
 RX = 1;
RC1 = 0; RC2 = 0;
for t = 1:size(transmit_BBF,1)
    BBF_mat = transmit_BBF(t,:);
    BBF_ID = bi2de(BBF_mat(1,1:2),'left-msb');
    if BBF_ID == 1 || BBF_ID == 2% Carrier 1
        uncompletedPDU1{256} = [];
        PACKETtimer1 = -1*ones(1, 256);
        completedPDU1 = [];
        completionTimeCarrier1 = [];
        
        R_BBf1 = transmit_BBF(t,81:usefull_bits+80);
        [completedPDU1, completionTimeCarrier1, uncompletedPDU1, PACKETtimer1] = GSEdecapsulatorMark2(R_BBf1, uncompletedPDU1, PACKETtimer1);
        RC1 = 1;
        for CN1=1:size(completedPDU1,2)
            reconstructed_PDU1(end+1,:) = cell2mat(completedPDU1(CN1));
%             
        end
        reconstructionTimeC1 = [reconstructionTimeC1, completionTimeCarrier1];
        totalreconstructed_PDU1 = [totalreconstructed_PDU1; reconstructed_PDU1];
%     elseif BBF_ID == 2 % Carrier 2
%         uncompletedPDU2{256} = [];
%         PACKETtimer2 = -1*ones(1, 256);
%         completedPDU2 = [];
%         completionTimeCarrier2 = [];
%         
%         R_BBf2 = cell2mat(transmit_BBF{1,t}(1,2:end));
%         [completedPDU2, completionTimeCarrier2, uncompletedPDU2, PACKETtimer2] = GSEdecapsulatorMark2(R_BBf2, uncompletedPDU2, PACKETtimer2);
%         RC2 = 1;
%         for CN2=1:size(completedPDU2,2)
%             reconstructed_PDU2(end+1,:) = cell2mat(completedPDU2(CN2));
%         end
%         reconstructionTimeC2 = [reconstructionTimeC2, completionTimeCarrier2];
%         totalreconstructed_PDU2 = [totalreconstructed_PDU2; reconstructed_PDU2];
    end
    
%     if (t==size(transmit_BBF,1))
%         if (RC1==1)&&(RC2==0)
%             [r, c] = size(reconstructed_PDU1);
%             for ZX = 1:r
%                 Received_PDU{RX,1} = 1;
%                 Received_PDU{RX,2} = reconstructed_PDU1(ZX,:);
%                 RX = RX + 1;
%             end
%         elseif (RC1==0)&&(RC2==1)
%             [r, c] = size(reconstructed_PDU2);
%             for ZX = 1:r
%                 Received_PDU{RX,1} = 2;
%                 Received_PDU{RX,2} = reconstructed_PDU2(ZX,:);
%                 RX = RX + 1;
%             end
%         elseif (RC1==1)&&(RC2==1)
%             ReconstructionTime = [reconstructionTimeC1, reconstructionTimeC2];
%             SortedReconstructionTime = sort(ReconstructionTime);
%             ZV = 1;
%             while(ZV<length(SortedReconstructionTime)+1)
%                 CheckC1 = ismember(SortedReconstructionTime(ZV), reconstructionTimeC1);
%                 CheckC2 = ismember(SortedReconstructionTime(ZV), reconstructionTimeC2);
%                 if (CheckC1==1)&&(CheckC2==0)
%                     PacketNumber1 = find(reconstructionTimeC1==SortedReconstructionTime(ZV));
%                     Received_PDU{RX,1} = 1;
%                     Received_PDU{RX,2} = reconstructed_PDU1(PacketNumber1,:);
%                     RX = RX + 1;
%                     ZV= ZV+1;
%                 elseif (CheckC1==0)&&(CheckC2==1)
%                     PacketNumber2 = find(reconstructionTimeC2==SortedReconstructionTime(ZV));
%                     Received_PDU{RX,1} = 2;
%                     Received_PDU{RX,2} = reconstructed_PDU2(PacketNumber2,:);
%                     RX = RX + 1;
%                     ZV= ZV+1;
%                 elseif (CheckC1==1)&&(CheckC2==1)
%                     PacketNumber1 = find(reconstructionTimeC1==SortedReconstructionTime(ZV));
%                     PacketNumber2 = find(reconstructionTimeC2==SortedReconstructionTime(ZV));
%                     Received_PDU{RX,1} = 1;
%                     Received_PDU{RX,2} = reconstructed_PDU1(PacketNumber1,:);
%                     RX = RX + 1;
%                     Received_PDU{RX,1} = 2;
%                     Received_PDU{RX,2} = reconstructed_PDU2(PacketNumber2,:);
%                     RX = RX + 1;
%                     ZV= ZV+2;
%                 end
%             end
%         end
%         RC1=0;
%         RC2=0;
%         reconstructionTimeC1 = [];
%         reconstructionTimeC2 = [];
%         reconstructed_PDU1 = [];
%         reconstructed_PDU2 = [];
%     end
end
Received_PDU = reconstructed_PDU1;