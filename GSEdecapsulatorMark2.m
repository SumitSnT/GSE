function [completedPDU, completionTime, uncompletedPDU, PACKETtimer] = GSEdecapsulatorMark2(BBframe, uncompletedPDU, PACKETtimer)
% 
% This function implement the GSE decapsulator.
%
% -------------------------------------------------------------------------
% Input:
%
% - BBframe: it is the main input argument. It is the BBframe (excluding 
%            the BBframe header) that contain the encapsulated GSE packets.
%
% - uncompletedPDU: It is the buffer where the fragments of the different 
%                   PDU are collected. It is a cell array variable with 256
%                   cells, one for each possible fragID. 
%                   When a fragment whit fragID equal to N is received, its
%                   data are stored in the cell-array in position equal to 
%                   N (the fragID value).                   
%
% - PACKETtimer: It is the counter for the expiration timer of the fragID
%                of the fragmented PDU. It is a vector of 256 elements, one
%                for each possible fragID. 
%                If uncompletedPDU{N} is empty -> PACKETtimer(N)=-1. 
%                When the first fragment with fragID = N is received ->
%                PACKETtimer(N)=0
%                At the end of each BBframe decapsulation the PACKETtimer
%                elements >=0 are incremented of 1. 
%                If PACKETtimer >= 256 -> PACKETtimeOUT error. The fragment
%                collected in uncompletedPDU{N} are discarder and
%                PACKETtimer = -1.
%
%--------------------------------------------------------------------------
% Output:
%
% - completedPDU: It is the buffer where the correctly reconstructed PDU
%                 are stored. It is a cell array with no fixed dimension.
%                 In this cell-array the correctly reconstructed PDU are
%                 stored consucutively once they are correctly
%                 reconstucted.
%
% - uncompletedPDU: It is the same of the input argument. It is present
%                   also as outup argument to track the current state of
%                   the buffer between the different calls to the
%                   decapsulator function.
%
% - PACKETtimer: It is the same of the input argument. It is present also 
%                as outup argument to track the current state of the buffer
%                between the different calls to the decapsulator function.
%
%--------------------------------------------------------------------------                
% Created by Nicola Maturo - February 2018
%
% SnT - University of Luxembourg

completedPDU = {};
completionTime = [];
BBframePosition = 0;

% Check PACKETtimeOUT
expiredTIMER = find(PACKETtimer==256);
if ~isempty(expiredTIMER)
    disp(['WARNING!!! The PDU with frag ID equal to ', num2str(expiredTIMER), ' was in the reconstruction phase for 256 BBframe.']); 
    disp('PACKETtimeOUT error. Buffered packets are discarded.');
    uncompletedPDU{expiredTIMER} = [];
    PACKETtimer(expiredTIMER) = -1;
end

DECAPpacketCOUNTER = 0;

STARTflagBIT  = 1;
ENDflagBIT = 2;
ENDflagBIT = 2;
LABELtypeBIT1 = 3;
LABELtypeBIT2 = 4;
GSElengthFIRSTbit = 5;
GSElengthLASTbit = 16;

fixedGSEheaderLENGHT = 2; %bytes


% Process the BBframe
while ~isempty(BBframe)
    if (BBframe(STARTflagBIT)==1)&&(BBframe(ENDflagBIT)==1)
        % The entire PDU is contained in one GSE packet.
        % Defining Significant bit positions and field length

        PROTOCOLtypeFIRSTbit = 17;
        PROTOCOLtypeLASTbit = 32;
        LABELaddressFIRSTbit = 33;
        
        % Reading GSE length field
        GSElength = bi2de(BBframe(GSElengthFIRSTbit:GSElengthLASTbit), 'left-msb');
        
        % Reading LABEL type field
        LABELtypeVALUE = [BBframe(LABELtypeBIT1), BBframe(LABELtypeBIT2)];
        if (LABELtypeVALUE(1)==0) && (LABELtypeVALUE(2)==0) % 6 bytes LABEL long
            LABELlength = 6; % Bytes
        elseif (LABELtypeVALUE(1)==0) && (LABELtypeVALUE(2)==1) % 3 bytes LABEL long
            LABELlength = 3; % Bytes    
        elseif (LABELtypeVALUE(1)==1) && (LABELtypeVALUE(2)==0) % No LABEL (broadcast packet)
            LABELlength = 0; % Bytes
        elseif (LABELtypeVALUE(1)==1) && (LABELtypeVALUE(2)==1) % No LABEL in this packet, LABEL reuse mode
            LABELlength = 0;
            
            if DECAPpacketCOUNTER == 0
                disp('ERROR!!! LABEL reuse mode is not allowed for the first packet of a BBframe. Packet discarder');
                % Removing the wrong GSE packet from the BBframe
                BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
                continue;
            end
        end  
        
        % Reading Protocol Type
        PROTOCOLtype = bi2de(BBframe(PROTOCOLtypeFIRSTbit:PROTOCOLtypeLASTbit), 'left-msb');
        
        % Reading LABEL address
        LABELaddress = BBframe(LABELaddressFIRSTbit:(LABELaddressFIRSTbit-1+LABELlength*8));
        
        % Reading the PDU data
        PDUdata = BBframe((LABELaddressFIRSTbit+LABELlength*8):(GSElength+fixedGSEheaderLENGHT)*8);
        
        % Writing the received data in the output
        completedPDU = [completedPDU, PDUdata];
        completionTime = [completionTime, BBframePosition+(GSElength+fixedGSEheaderLENGHT)*8];
        
    elseif (BBframe(STARTflagBIT)==1)&&(BBframe(ENDflagBIT)==0)
        % The PDU is fragmented and the current fragment is the first one
        % Redefining some Significant bit positions
        fragIDfirstBIT = 17;
        fragIDlastBIT = 24;
        TOTALlengthFIRSTbit = 25;
        TOTALlengthLASTbit = 40;
        PROTOCOLtypeFIRSTbit = 41;
        PROTOCOLtypeLASTbit = 56;
        LABELaddressFIRSTbit = 57;
        
        % Reading GSE length field
        GSElength = bi2de(BBframe(GSElengthFIRSTbit:GSElengthLASTbit), 'left-msb');
        
        % Reading LABEL type field
        LABELtypeVALUE = [BBframe(LABELtypeBIT1), BBframe(LABELtypeBIT2)];
        if (LABELtypeVALUE(1)==0) && (LABELtypeVALUE(2)==0) % 6 bytes LABEL long
            LABELlength = 6; % Bytes
        elseif (LABELtypeVALUE(1)==0) && (LABELtypeVALUE(2)==1) % 3 bytes LABEL long
            LABELlength = 3; % Bytes    
        elseif (LABELtypeVALUE(1)==1) && (LABELtypeVALUE(2)==0) % No LABEL (broadcast packet)
            LABELlength = 0; % Bytes
        else 
            disp('ERROR!!! LABEL type incompatible with the first fragment of the PDU. Fragment discarded');
            % Removing the wrong GSE packet from the BBframe
            BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
            continue;
        end
        
        % Reading the fragment ID field
        fragID = bi2de(BBframe(fragIDfirstBIT:fragIDlastBIT), 'left-msb');
        
        % Checking if some fragments with this fragID is already buffered.
        % If this is the case they are discarded.
        if ~isempty(uncompletedPDU{fragID})
            disp('WARNING!!! Packets with the same fragID of this start fragment already buffered. The buffered packets are discarded');
            uncompletedPDU{fragID}=[];
        end
                
        % Reading Total Length field
        TOTALlength = bi2de(BBframe(TOTALlengthFIRSTbit:TOTALlengthLASTbit), 'left-msb');
       
        % Reading Protocol Type
        PROTOCOLtype = bi2de(BBframe(PROTOCOLtypeFIRSTbit:PROTOCOLtypeLASTbit), 'left-msb');
       
        % Reading LABEL address
        LABELaddress = BBframe(LABELaddressFIRSTbit:(LABELaddressFIRSTbit-1+LABELlength*8));
       
        % Writing the received data in the output. For the first fragment
        % the header need to be saved too.
        uncompletedPDU{fragID} = [BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8)];
        
        % Updating GSEtimeOUT for the received fragment
        PACKETtimer(fragID) = 0;
        
    elseif (BBframe(1)==0)&&(BBframe(2)==1)
        % The PDU is fragmented and the current fragment is the last one
        % Redefining some Significant bit positions
        fragIDfirstBIT = 17;
        fragIDlastBIT = 24;
        TOTALlengthFIRSTbit = 25;
        TOTALlengthLASTbit = 40;
        firstFRAGheaderLENGTH = TOTALlengthLASTbit;
        PROTOCOLtypeFIRSTbit = 41;
        PROTOCOLtypeLASTbit = 56;
        LABELaddressFIRSTbit = 57;
        CRClength = 32;
        % Reading GSE length field
        GSElength = bi2de(BBframe(GSElengthFIRSTbit:GSElengthLASTbit), 'left-msb');
        
        % Reading the fragment ID field
        fragID = bi2de(BBframe(fragIDfirstBIT:fragIDlastBIT), 'left-msb');
        
        % Reading LABEL type field
        LABELtypeVALUE = [BBframe(LABELtypeBIT1), BBframe(LABELtypeBIT2)];
        if (LABELtypeVALUE(1)==uncompletedPDU{fragID}(LABELtypeBIT1)) && (LABELtypeVALUE(2)==uncompletedPDU{fragID}(LABELtypeBIT2)) % CHECK LABELtype
            % Reading LABEL field length from the header of the first
            % fragment of this fragID to get the length of the label field.
            % This is needed for PDU reconstraction.
            if (uncompletedPDU{fragID}(LABELtypeBIT1)==0) && (uncompletedPDU{fragID}(LABELtypeBIT2)==0) % 6 bytes LABEL long
                LABELlength = 6; % Bytes
            elseif (uncompletedPDU{fragID}(LABELtypeBIT1)==0) && (uncompletedPDU{fragID}(LABELtypeBIT2)==1) % 3 bytes LABEL long
                LABELlength = 3; % Bytes    
            elseif (uncompletedPDU{fragID}(LABELtypeBIT1)==1) && (uncompletedPDU{fragID}(LABELtypeBIT2)==0) % No LABEL (broadcast packet)
                LABELlength = 0; % Bytes
            end
        else 
            disp('ERROR!!! LABEL type incompatible with the rest of the PDU. Fragment discarded');
            % Removing the wrong GSE packet from the BBframe
            BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
            continue;
        end
        
        % Checking if some fragments with this fragID is already buffered.
        % If this is not the case this packet is discarded.
        if isempty(uncompletedPDU{fragID})
            disp('ERROR!!! Last fragment of not already buffered fragID received. Fragment discarded');
            % Removing the padding GSE packet from the BBframe
            BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
            continue;
        end
        
        % Reading the PDU data
        PDUdata = BBframe(fragIDlastBIT+1:((GSElength+fixedGSEheaderLENGHT)*8-CRClength));
        
        % Writing the received data in the output
        uncompletedPDU{fragID} = [uncompletedPDU{fragID}, PDUdata];
        
        % Reading CRC32 value
        CRCvalue = BBframe(((GSElength+fixedGSEheaderLENGHT)*8-CRClength+1):(GSElength+fixedGSEheaderLENGHT)*8);
        
        % Check of the PDU length
        localPDUlength = length(uncompletedPDU{fragID})-firstFRAGheaderLENGTH+CRClength;
        
        % Reading TOTAL length from the header of the first fragment of
        % this fragID
        TOTALlength = bi2de(uncompletedPDU{fragID}(TOTALlengthFIRSTbit:firstFRAGheaderLENGTH), 'left-msb');
                
        if (localPDUlength==TOTALlength*8)
%             disp('SUCCESSFULL TOTAL LENGTH CHECK');
        else
            disp('!!!! ERROR - FAILED TOTAL LENGTH CHECK - PDU DISCARDED !!!!');
        end
        
        % Calculate the local CRC32 value
        localCRCvalue = crc32(uncompletedPDU{fragID}(TOTALlengthFIRSTbit:end));
        
        if sum(xor(localCRCvalue, CRCvalue))==0
            completedPDU = [completedPDU, uncompletedPDU{fragID}(((PROTOCOLtypeLASTbit/8)+LABELlength)*8+1:end)];
            completionTime = [completionTime, BBframePosition+((GSElength+fixedGSEheaderLENGHT)*8+CRClength)];
%             disp('SUCCESSFULL CRC CHECK - PDU CORRECTLY RECOMPOSED');
        else
            disp('!!!! FAILED CRC CHECK - PDU DISCARDED !!!!'); 
        end
        
        % Free the buffer reserved for the PDU with this fragID 
        uncompletedPDU{fragID} = [];
        
        % Reset the GSEtimeOUT of this frag ID
        PACKETtimer(fragID) = -1;
        
    else 
        % Start and end flag equal to 0. This can be the continuation of a
        % fragmented PDU or a padding GSE packet (depending on label type)
        % redefining some Significant bit position
        fragIDfirstBIT = 17;
        fragIDlastBIT = 24;
        TOTALlengthFIRSTbit = 25;
        TOTALlengthLASTbit = 40;
        firstFRAGheaderLENGTH = 40;
        % Reading GSE length field
        GSElength = bi2de(BBframe(GSElengthFIRSTbit:GSElengthLASTbit), 'left-msb');
        
        % Reading the fragment ID field
        fragID = bi2de(BBframe(fragIDfirstBIT:fragIDlastBIT), 'left-msb');
        
        % Reading LABEL type field
        LABELtypeVALUE = [BBframe(LABELtypeBIT1), BBframe(LABELtypeBIT2)];
        if (LABELtypeVALUE(1)==0) && (LABELtypeVALUE(2)==0) && (GSElength==0) % Padding Packet
            disp('WARNING!!! The current packet is a padding packet. Packet discarded');
            % Removing the padding GSE packet from the BBframe
            BBframe(1:end) = [];
            continue;
                        
        elseif (LABELtypeVALUE(1)==uncompletedPDU{fragID}(LABELtypeBIT1)) && (LABELtypeVALUE(2)==uncompletedPDU{fragID}(LABELtypeBIT2)) && (GSElength>0) % LABEL check - PDU continuation
            
        
            % Checking if some fragments with this fragID is already buffered.
            % If this is not the case this packet is discarded.    
            if isempty(uncompletedPDU{fragID})
                disp('ERROR!!! Continuation fragment of a not already buffered fragID received. Fragment discarded');
                % Removing the padding GSE packet from the BBframe
                BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
                continue;
            end
            
            % Reading the PDU data
            PDUdata = BBframe(fragIDlastBIT+1:((GSElength+fixedGSEheaderLENGHT)*8));
            
            % NOTE: add a check of the length with respect to TOTALlength
            % field. If actualLength > TOTALlength discard all the
            % collected fragments.
            
            % Reading TOTAL length from the header of the first fragment of
            % this fragID
            TOTALlength = bi2de(uncompletedPDU{fragID}(TOTALlengthFIRSTbit:TOTALlengthLASTbit), 'left-msb');
            
            % Evaluating the current length for the considered fragID
            currectLENGTH = length(uncompletedPDU{fragID}) - firstFRAGheaderLENGTH + length(PDUdata);
            if (currectLENGTH<TOTALlength*8)
%                 disp('SUCCESSFULL CURRENT LENGTH CHECK');
                % Writing the DATA in the buffer
                uncompletedPDU{fragID} = [uncompletedPDU{fragID}, PDUdata];
            else
                disp('!!!! ERROR - FAILED CURRENT LENGTH CHECK - PDU DISCARDED !!!!');
            end            
           
        else 
            disp('ERROR!!! LABEL type incompatible. Fragment discarded');
            % Removing the wrong GSE packet from the BBframe
            BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
            continue;
        end
        
        
    end
    
    % Removing the decapsulated GSE packet from the BBframe
    BBframePosition = BBframePosition + (GSElength+fixedGSEheaderLENGHT)*8;
    BBframe(1:(GSElength+fixedGSEheaderLENGHT)*8) = [];
    DECAPpacketCOUNTER = DECAPpacketCOUNTER + 1;
end    

% Updating GSEtimeOUT
PACKETtimer = PACKETtimer + double(PACKETtimer>=0); 

end

