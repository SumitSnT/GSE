function [transmit_BBF, BBF_useful_bits] = Transmitter(S1,SNR,FR)

% GSE Parameters:----------------------------------------------------------
jj = 1;                     % GSE Counter
LABELlength = 3;            % 3 or 6 bytes
NETlayerPROTOCOL = 34525;   % IPv6
fragID_1 = 0;               % Carrier 1
LABELaddress_1 = randi([0 1], 1, LABELlength*8);
fragID_2 = 0;               % Carrier 2
LABELaddress_2 = randi([0 1], 1, LABELlength*8);
% -------------------------------------------------------------------------
[~,~,CR] = loglike_coderate2(SNR);
BBF_useful_bits = min(4095*8,floor(64800*CR*FR/8)*8)-80;
B1 = 1;         % Carrier BBFrame
Q1 = 0;         % BBFrame counter
L = BBF_useful_bits;
BBF_length = floor(64800*CR*FR/8)*8;
BBFrame_header = [0 1 randi([0 1], 1,78)];
BBFrame{1,1} = {BBFrame_header};
transmit_BBF = {};q=1;

L_padding = 64800-BBF_useful_bits-80;
z_padding = zeros(1,L_padding);
user_BBF = []; 
for p = 1:size(S1,1)
        [GSEpackets_A{jj}, fragID_1]= GSEencapsulatorMark2(L/8,BBF_useful_bits/8, S1(p,:), NETlayerPROTOCOL, 0, LABELaddress_1, fragID_1);
        [~, columns] = size(GSEpackets_A{jj});
        for ZX=1:columns
            L = L - cellfun('length',GSEpackets_A{jj}(ZX));
            if L < 88
                L = BBF_useful_bits;
            end
        end
        for m = 1:sum(cellfun('size',GSEpackets_A(jj),2)) % Carrier 1 BBFrame Creation:
            if cellfun('size',GSEpackets_A{jj}(m),2) <= BBF_length - length(cell2mat(BBFrame{1,B1}(1:end)))
                BBFrame{1,B1} = [BBFrame{1,B1}, GSEpackets_A{jj}(m)];
                filled_BBframe1 = cellfun('size',BBFrame{1,B1},2);
                BBFrame_Leftover1 =  BBF_useful_bits - sum(filled_BBframe1(2:end));
                if BBFrame_Leftover1<88
                    transmit_BBF{1,q} = [BBFrame{1,B1},z_padding]; % create BBFrame + zero padding 
                    user_BBF=[user_BBF; cell2mat([transmit_BBF{1,q}])]; 
                    q = q +1;
                    Q1 = Q1 + 1;
                    B1 = B1 + 1; % Next BBFrame
                    BBFrame_header = [0 1 randi([0 1], 1,78)];
                    BBFrame{1,B1} = {BBFrame_header};
                end
            elseif cellfun('size',GSEpackets_A{jj}(m),2) > BBF_length - length(cell2mat(BBFrame{1,B1}))
                BBFrame{1,B1} = [BBFrame{1,B1}, GSEpackets_A{jj}(m)];
            end
        end
        jj = jj + 1; % Next GSE
end

if length(cell2mat(BBFrame{1,B1}))~= BBF_length
    pz_end = zeros(1,64800-length(cell2mat(BBFrame{1,B1})));
    transmit_BBF{1,q} = [BBFrame{1,B1}, pz_end];
    user_BBF = [user_BBF; cell2mat([transmit_BBF{1,q}])]; 
    q = q +1;
end

transmit_BBF=user_BBF;
