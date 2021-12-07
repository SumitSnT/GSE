function [GSEpackets, fragID] = GSEencapsulatorMark2(firstGSElength, secondGSElength, varargin)
%
% This function implement the GSE encapsulator, with some additional
% feature required by the CADSAT project.
%
% -------------------------------------------------------------------------
% Mandatory Input argument:
%
% - firstGSElength: It is the length of the first GSE packet of a PDU to be
%              created.
%              This first packet length should take into account if the
%              BBFRAME available length has already be partially used by
%              the previous PDU. If this is the case,
%              firstGSElength < secondGSElength
%              Otherwise if we can use the entire BBFRAME
%              firstGSElength = secondGSElength
%
% - secondGSElength: It is the length of the second GSE packet of a PDU to be
%              created.
%              The second GSE packet will for sure have the BBFRAME just
%              for its usage, so this length value it is only related to
%              the MODCOD and the fill rate defined for this user.
%
% Optional Input arguments:
%
% - PDU: It is a vector of 0 and 1 representing the PDU to be encapsulated.
%        If present it implies that also NETlayerPROTOCOL must be present.
%
% - NETlayerPROTOCOL: it is an integer value, up to 65535, representing the
%                     protocol used in the network layer PDU. It is always
%                     present when a PDU is specified.
%
% - LABELreuseFLAG: if it is equal to 1 it implies that the LABELtype bits
%                   must be setted to the Label reuse value [1,1].
%                   In this case the current GSE packet refer to the same
%                   label adrress of the previous GSE packet but it is here
%                   omitted for the sake of saving bytes.
%                   It can be applied only on multiple GSE packets carrying
%                   an entire PDU that are scheduled in the same BBframe.
%
% - LABELaddress: it represents the address to be inserted in the label
%                 field of the GSE packet for users filtering. It can be 3
%                 bytes long, 6 bytes long or it can be assent (meaning a
%                 broadcast/multicast packet).
%
% - fragID: it is a identification number for fragments coming from the
%           same PDU. The value of the fragID can be between 0 and 255.
%           This ID will be included in GSE packets only when fragmentation
%           is required.
%
% According to the number of inut values used to call the function,
% different type of GSE packet are generated:
%
% [GSEpackets, fragID] = GSEencapsulatorMark2(firstGSElength,
% secondGSElength) -> Zero Padding Packet with length equal to
% firstGSElength value.
%
% [GSEpackets, fragID] = GSEencapsulatorMark2(firstGSElength,
% secondGSElength, PDU, NETlayerPROTOCOL) -> PDU encapsulation with no
% Label
%
% [GSEpackets, fragID] = GSEencapsulatorMark2(firstGSElength,
% secondGSElength, PDU, NETlayerPROTOCOL, LABELreuseFLAG) -> PDU
% encapsulation with Label reuse mode
%
% [GSEpackets, fragID] = GSEencapsulatorMark2(firstGSElength,
% secondGSElength, PDU, NETlayerPROTOCOL, LABELreuseFLAG, LabelAddress) ->
% PDU encapsulation with specified Label address
%
% [GSEpackets, fragID] = GSEencapsulatorMark2(firstGSElength,
% secondGSElength, PDU, NETlayerPROTOCOL, LABELreuseFLAG, LabelAddress,
% fragID) -> PDU encapsulation with specified Label address and fragID
%
% The last one is what it should be maily used for CADSAT project
% -------------------------------------------------------------------------
% Output arguments:
%
% - GSEpackets: it will carry the encapsulated GSE packet/s of the actual
%               PDU. In particular this variable is a MATLAB cell-array
%               were each element of the cell-array is a GSE packet.
%               Clearly if fragmentation is not required the cell-array
%               will include only 1 element (1 GSE packet).
%
% - fragID: it has the same meaning of the fragID defined as input. It is
%           also in the output to keep its value updated, because clearly
%           it is not possible to reuse that value before the transmission
%           of that PDU is not completed.
%
%--------------------------------------------------------------------------
% Created by Nicola Maturo - April 2019
%
% SnT - University of Luxembourg

% Check on the values of the fragment ID, of the newtork layer protocol and
% of the length of the GSE packet

if (firstGSElength > 4095)
    error('ERROR!!! First GSE length value is out of range(max 4095)');
end

if (secondGSElength > 4095)
    error('ERROR!!! Second GSE length value is out of range(max 4095)');
end

% For the first fragment the maximum length of the packet is equal to the
% input value firstGSElength, because it can happen that the current PDU
% have to share the BBFRAME with the last fragment from the previous PDU.
maxGSElength = firstGSElength; %bytes

if nargin == 2
    % Padding
    PDU = [];
    NETlayerPROTOCOL = 0;
    LABELreuseFLAG = 0;
    LABELaddress = [];
    fragID = 0;
    paddingFLAG = 1;
elseif nargin == 4
    % PDU with no LABEL
    PDU = varargin{1};
    NETlayerPROTOCOL = varargin{2};
    LABELreuseFLAG = 0;
    LABELaddress = [];
    fragID = 0;
    paddingFLAG = 0;
elseif nargin == 5
    % PDU with LABEL reuse mode
    PDU = varargin{1};
    NETlayerPROTOCOL = varargin{2};
    LABELreuseFLAG = varargin{3};
    LABELaddress = [];
    fragID = 0;
    paddingFLAG = 0;
elseif nargin == 6
    % PDU with specified LABEL
    PDU = varargin{1};
    NETlayerPROTOCOL = varargin{2};
    if varargin{3}~=0
        disp('!!! WARNING !!! LABEL REUSE MODE is not allowed when a label address is specified as input. I will perform the encapsulation in NO LABEL REUSE MODE using the LABEL address provided as an input. See function help for more info.');
    end
    LABELreuseFLAG = 0;
    LABELaddress = varargin{4};
    fragID = 0;
    paddingFLAG = 0;
elseif nargin == 7
    % PDU with specified LABEL and specified fragID
    PDU = varargin{1};
    NETlayerPROTOCOL = varargin{2};
    if varargin{3}~=0
        disp('!!! WARNING !!! LABEL REUSE MODE is not allowed when a label address is specified as input. I will perform the encapsulation in NO LABEL REUSE MODE using the LABEL address provided as an input. See function help for more info.');
    end
    LABELreuseFLAG = 0;
    LABELaddress = varargin{4};
    fragID = varargin{5};
    paddingFLAG = 0;
else
    error('ERROR!!! Invalid number of input arguments. Allowed number of inputs: 1 (padding packet), 4(PDU with no Label), 5(PDU with Label reuse mode), 6(PDU with specified Label), 7(PDU with specified Label and specified fragID');
end

if (fragID > 255)
    error('ERROR!!! Fragment ID value is out of range (0-255)');
end

if (NETlayerPROTOCOL > 65535)
    error('ERROR!!! Network Layer Protocol value is out of range(max 65535)');
end

PDUlength = ceil(length(PDU)/8); %bytes
LABELlength = ceil(length(LABELaddress)/8); % evaluate length of the Label field
PROTOCOLtype = de2bi(NETlayerPROTOCOL, 16, 'left-msb');
PROTOCOLtypeLENGTH = 2;%bytes
GSEheaderLENGTH = 2;%bytes
CRClength = 4;%bytes
fragIDlength = 1;%bytes
EXTENSIONheaderLENGTH = 0;
EXTENSIONheaderBYTE = [];

if (paddingFLAG == 1)
    % Padding packet
    % Header
    STARTflag = 0;
    ENDflag = 0;
    LABELtype = [0 0];
    GSElength = zeros(1, 12);
    
    % Data
    Data = zeros(1, (maxGSElength-GSEheaderLENGTH)*8);
    
    % Packet
    GSEpackets{1} = [STARTflag, ENDflag, LABELtype, GSElength, Data];
    
else
    % Unfragmented PDU: The check is done considering the maximum length of
    % the first GSE packet.
    if (ceil(PDUlength /(maxGSElength - GSEheaderLENGTH - PROTOCOLtypeLENGTH - LABELlength)) == 1)
        
        STARTflag = 1;
        ENDflag = 1;
        
        if (LABELlength==0)&&(LABELreuseFLAG==0)
            LABELtype = [1 0];
        elseif (LABELlength==0)&&(LABELreuseFLAG==1)
            LABELtype = [1 1];
        elseif (LABELlength==3)
            LABELtype = [0 1];
        elseif (LABELlength==6)
            LABELtype = [0 0];
        else
            error('ERROR!!! Invalid LABEL address');
        end
        
        GSElength = de2bi((PDUlength + PROTOCOLtypeLENGTH + LABELlength), 12, 'left-msb');
        
        header = [STARTflag, ENDflag, LABELtype, GSElength, PROTOCOLtype, LABELaddress];
        
        GSEpackets{1} = [header, PDU];
        
    else % Fragmented PDU
        
        fragID = fragID + 1;
        copyPDU = PDU;
        TOTALfieldLENGTH = 2;
        % First Fragment
        STARTflag = 1;
        ENDflag = 0;
        
        if (LABELlength==0)
            LABELtype = [1 0];
        elseif (LABELlength==3)
            LABELtype = [0 1];
        elseif (LABELlength==6)
            LABELtype = [0 0];
        else
            error('ERROR!!! Invalid GSE address');
        end
        
        GSElength = de2bi(maxGSElength-GSEheaderLENGTH, 12, 'left-msb');
        
        fragIDbyte = de2bi(fragID, 8, 'left-msb');
        
        totalLENGTHbyte = de2bi((PROTOCOLtypeLENGTH + LABELlength + EXTENSIONheaderLENGTH + PDUlength + CRClength ), 16, 'left-msb');
        
        header = [STARTflag, ENDflag, LABELtype, GSElength, fragIDbyte, totalLENGTHbyte, PROTOCOLtype, LABELaddress, EXTENSIONheaderBYTE];
        
        fragPDU = PDU(1:(maxGSElength - (GSEheaderLENGTH + fragIDlength + TOTALfieldLENGTH + PROTOCOLtypeLENGTH + LABELlength + EXTENSIONheaderLENGTH))*8); % 2 is the bytes of total length field and 2 is the bytes of protocol type field
        
        copyPDU(1:(maxGSElength - (GSEheaderLENGTH + fragIDlength + TOTALfieldLENGTH + PROTOCOLtypeLENGTH + LABELlength + EXTENSIONheaderLENGTH))*8) = [];
        
        GSEpackets{1} = [header, fragPDU];
        
        % End of First Fragment - CRC32 Evaluation
        CRCdata = [totalLENGTHbyte, PROTOCOLtype, LABELaddress, EXTENSIONheaderBYTE, PDU];
        CRC32val = crc32(CRCdata);
        
        % From the second fragment the length of the packet is equal to
        % secondGSE length input, because in this case the entire BBFRAME
        % will be used just for the fragment of this PDU.
        
        maxGSElength = secondGSElength;
        % Evaluate the number of remaining fragments
        fragNUM = ceil((length(copyPDU)/8 + CRClength) / (maxGSElength-fragIDlength-GSEheaderLENGTH));
        
        %Creation of the other fragments
        for ZX=1:fragNUM
            
            if (ZX==fragNUM) % creation of the last fragment of the PDU
                STARTflag = 0;
                ENDflag = 1;
                
                % LABELtype should be the same of the first fragment
                
                GSElength = de2bi(length(copyPDU)/8 + fragIDlength + CRClength, 12, 'left-msb'); %  4 are the bytes of the CRC32
                
                fragIDbyte = de2bi(fragID, 8, 'left-msb');
                
                header = [STARTflag, ENDflag, LABELtype, GSElength, fragIDbyte];
                
                fragPDU = copyPDU(1:end);
                
                GSEpackets{ZX+1} = [header, fragPDU, CRC32val];
                
            else % intermediate fragments of the PDU
                STARTflag = 0;
                ENDflag = 0;
                
                % LABELtype should be the same of the first fragment
                
                leftoverLength = length(copyPDU)/8;
                maxGSEdimension = (maxGSElength-3);
                
                if maxGSEdimension < leftoverLength
                    GSElength = de2bi((maxGSElength-2), 12, 'left-msb'); %  1 is the byte of frag ID field
                
                    fragIDbyte = de2bi(fragID, 8, 'left-msb');
                
                    header = [STARTflag, ENDflag, LABELtype, GSElength, fragIDbyte];
                
                    fragPDU = copyPDU(1:((maxGSElength-3)*8));
                
                    copyPDU(1:((maxGSElength-3)*8)) = [];
                
                    GSEpackets{ZX+1} = [header, fragPDU];
                else 
                    GSElength = de2bi((leftoverLength-1+1), 12, 'left-msb'); %  save 1 byte for the last fragment / add 1 byte for the fragID
                    
                    fragIDbyte = de2bi(fragID, 8, 'left-msb');
                    
                    header = [STARTflag, ENDflag, LABELtype, GSElength, fragIDbyte];
                    
                    fragPDU = copyPDU(1:((leftoverLength-1)*8));
                    
                    copyPDU(1:((leftoverLength-1)*8)) = [];
                    
                    GSEpackets{ZX+1} = [header, fragPDU];
                end
                
            end
        end
        
    end
end


end

