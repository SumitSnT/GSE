function [SE,mod_ord,codeRate] = loglike_coderate2(SNR)
% This is a modified version (by Hayder Al-Hraishawi) of a previous function 
% from Nicola Maturo. 
% In this version of the function includes only the ModCods that are implemented
% in the HW (SnT ComLab)
% This function takes SNR as an input and returns 3 outputs:
% - ind_modcod: is the index of the selected DVB-S2X modcod.
%   (Please note that not all the modcods of the standard are included in this function
% - SE: is the spectral efficiency of the selected modcod
% - mod_ord: is the order of the selected modulation. The possible values
%            are 4(QPSK), 8(8PSK), 16(16PSK), 32(32PSK), 64(64PSK),
%            128(128PSK) and 256(256PSK)
% - coderate: it is the coderate of the selected modcod.
% -------------------------------------------------------------------------
% SNR_data = xlsread('modcods_2x');
load('dvb_s2_modcod.mat')
L_s = length(SNR_data);
        
if SNR < SNR_data(1,1) % Choose the minimum SE and modulation order available for low SNRs
    mod_ord = SNR_data(1,2);
    codeRate = SNR_data(1,3);
    SE = SNR_data(1,4);
else
    if SNR <= SNR_data(L_s,1)
        ind = find(SNR_data(:,1) <= SNR); % find the MODCOD with the highest possible SE
        ind_modcod = ind(length(ind));
        mod_ord = SNR_data(ind_modcod(end),2);
        codeRate = SNR_data(ind_modcod(end),3);
        SE = SNR_data(ind_modcod(end),4);
    else
        ind_modcod = L_s;
        mod_ord = SNR_data(ind_modcod(end),2);
        codeRate = SNR_data(ind_modcod(end),3);
        SE = SNR_data(ind_modcod(end),4);
    end
end
        
% %------------------------------------------------------------------------
% switch ind_modcod
%     case 1
%         modulationType = 'QPSK';
%         codeRate = 2/9;
%         codeRateNum = 2;
%         codeRateDen = 9;
%         %         FecFrameLength = FECNormalLength;
%         dvb.PuncturingP=15;
%         dvb.PuncturingXp=3240;
%         dvb.VLSNRLdpcCodedBlockLength = 61560;
%         dvb.SF2Modcod = 65;
%     case 2
%         modulationType = 'QPSK';
%         codeRate = 1/4;
%         codeRateNum = 1;
%         codeRateDen = 4;
%     case 3
%         modulationType = 'QPSK';
%         codeRate = 13/45;
%         codeRateNum = 13;
%         codeRateDen = 45;
%         %         FecFrameLength = FECNormalLength;
%         dvb.SF2Modcod = 66;
%     case 4
%         modulationType = 'QPSK';
%         codeRate = 1/3;
%         codeRateNum = 1;
%         codeRateDen = 3;
%     case 5
%         modulationType = 'QPSK';
%         codeRate = 2/5;
%         codeRateNum = 2;
%         codeRateDen = 5;
%     case 6
%         modulationType = 'QPSK';
%         codeRate = 9/20;
%         codeRateNum = 9;
%         codeRateDen = 20;
%         %         FecFrameLength = FECNormalLength;
%         dvb.SF2Modcod = 67;
%     case 7
%         modulationType = 'QPSK';
%         codeRate = 1/2;
%         codeRateNum = 1;
%         codeRateDen = 2;
%     case 8
%         modulationType = 'QPSK';
%         codeRate = 11/20;
%         codeRateNum = 11;
%         codeRateDen = 20;
%         %         FecFrameLength = FECNormalLength;
%         dvb.SF2Modcod = 68;
%     case 9
%         modulationType = 'QPSK';
%         codeRate = 3/5;
%         codeRateNum = 3;
%         codeRateDen = 5;
%     case 10
%         modulationType = 'QPSK';
%         codeRate = 2/3;
%         codeRateNum = 2;
%         codeRateDen = 3;
%     case 11
%         modulationType = 'QPSK';
%         codeRate = 3/4;
%         codeRateNum = 3;
%         codeRateDen = 4;
%     case 12
%         modulationType = 'QPSK';
%         codeRate = 4/5;
%         codeRateNum = 4;
%         codeRateDen = 5;
%     case 13
%         modulationType = '8PSK';
%         codeRate = 5/9;
%         codeRateNum = 5;
%         codeRateDen = 9;
%     case 14
%         modulationType = '8PSK';
%         codeRate = 26/45;
%         codeRateNum = 26;
%         codeRateDen = 45;
%     case 15
%         modulationType = '8PSK';
%         codeRate = 3/5;
%         codeRateNum = 3;
%         codeRateDen = 5;
%     case 16
%         modulationType = '16APSK';
%         constRatioRadius=2.19;
%         codeRate = 90/180;
%         codeRateNum = 90;
%         codeRateDen = 180;
%         %        FecFrameLength = FECNormalLength;
%         BitInterleavePattern=[3 2 1 0];
%         dvb.SF2Modcod = 74;
%     case 17
%         modulationType = '16PSK';
%         codeRate = 8/15;
%         codeRateNum = 8;
%         codeRateDen = 15;
%     case 18
%         modulationType = '16PSK';
%         codeRate = 5/9;
%         codeRateNum = 5;
%         codeRateDen = 9;
%     case 19
%         modulationType = '16PSK';
%         codeRate = 3/5;
%         codeRateNum = 3;
%         codeRateDen = 5;
%     case 20
%         modulationType = '16PSK-L';
%         codeRate = 3/5;
%         codeRateNum = 3;
%         codeRateDen = 5;
%     case 21
%         modulationType = '16PSK';
%         codeRate = 28/45;
%         codeRateNum = 28;
%         codeRateDen = 45;
%     case 22
%         modulationType = '16PSK';
%         codeRate = 23/36;
%         codeRateNum = 23;
%         codeRateDen = 36;
%     case 23
%         modulationType = '16PSK-L';
%         codeRate = 2/3;
%         codeRateNum = 2;
%         codeRateDen = 3;
%     case 24
%         modulationType = '16APSK';
%         constRatioRadius=3.15;
%         codeRate = 2/3;
%         codeRateNum = 2;
%         codeRateDen = 3;
%     case 25
%         modulationType = '16PSK';
%         codeRate = 25/36;
%         codeRateNum = 25;
%         codeRateDen = 36;
%     case 26
%         modulationType = '16PSK';
%         codeRate = 13/18;
%         codeRateNum = 13;
%         codeRateDen = 18;
%     case 27
%         modulationType = '16PSK';
%         codeRate = 3/4;
%         codeRateNum = 3;
%         codeRateDen = 4;
%     case 28
%         modulationType = '16PSK';
%         codeRate = 7/9;
%         codeRateNum = 7;
%         codeRateDen = 9;
%     case 29
%         modulationType = '16PSK';
%         codeRate = 4/5;
%         codeRateNum = 4;
%         codeRateDen = 5;
%     case 30
%         modulationType = '32PSKL';
%         codeRate = 2/3;
%         codeRateNum = 2;
%         codeRateDen = 3;
%     case 31
%         modulationType = '16APSK';
%         codeRate = 5/6;
%         codeRateNum = 5;
%         codeRateDen = 6;
%     case 32
%         modulationType = '32APSK';
%         codeRate = 32/45;
%         codeRateNum = 32;
%         codeRateDen = 45;
%     case 33
%         modulationType = '32APSK';
%         codeRate = 11/15;
%         codeRateNum = 11;
%         codeRateDen = 15;
%     case 34
%         modulationType = '32APSK';
%         codeRate = 3/4;
%         codeRateNum = 3;
%         codeRateDen = 4;
%     case 35
%         modulationType = '32APSK';
%         codeRate = 7/9;
%         codeRateNum = 7;
%         codeRateDen = 9;
%     case 36
%         modulationType = '32APSK';
%         codeRate = 4/5;
%         codeRateNum = 4;
%         codeRateDen = 5;
%     case 37
%         modulationType = '64APSKl';
%         codeRate = 32/45;
%         codeRateNum = 32;
%         codeRateDen = 45;
%     case 38
%         modulationType = '64APSK';
%         codeRate = 11/15;
%         codeRateNum = 11;
%         codeRateDen = 15;
%     case 39
%         modulationType = '64APSK';
%         codeRate = 7/9;
%         codeRateNum = 7;
%         codeRateDen = 9;
%     case 40
%         modulationType = '64APSK';
%         codeRate = 4/5;
%         codeRateNum = 4;
%         codeRateDen = 5;
%     case 41
%         modulationType = '64APSK';
%         codeRate = 5/6;
%         codeRateNum = 5;
%         codeRateDen = 6;
%     case 42
%         modulationType = '256APSKl';
%         codeRate = 29/45;
%         codeRateNum = 29;
%         codeRateDen = 45;
%     case 43
%         modulationType = '256APSK';
%         codeRate = 2/3;
%         codeRateNum = 2;
%         codeRateDen = 3;
%     case 44
%         modulationType = '256APSK';
%         codeRate = 31/45;
%         codeRateNum = 31;
%         codeRateDen = 45;
%     case 45
%         modulationType = '256APSK';
%         codeRate = 32/45;
%         codeRateNum = 32;
%         codeRateDen = 45;
%     case 46
%         modulationType = '256APSKl';
%         codeRate = 11/15;
%         codeRateNum = 11;
%         codeRateDen = 15;
%     case 47
%         modulationType = '256APSK';
%         codeRate = 3/4;
%         codeRateNum = 3;
%         codeRateDen = 4;
%     otherwise
%         error('InvalidMODCOD');
% end
% 
% 
% 
% end