function [timeData,info,Header] = importHDF(fileName)
%read header 

default = fileread(fileName);

% default value for header length
Header = default(1:65536-1);
data = default(65537:end);
Header = regexp(Header,'\n','split')';

Header = cellfun(@join,Header,'UniformOutput',false);
numbers =regexp(Header,'[0-9]');
numbers = cellfun(@(C1,C2) str2num(C1(C2)),Header,numbers,'UniformOutput',false);

if numbers{contains(Header,'start of data')} ~= 65536
   Header =  default(1:numbers{contains(Header,'start of data')});
   Header = regexp(Header,'\n','split')';
   Header =cellfun(@join,Header,'UniformOutput',false)';
%    Header = regexp(Header,'[^;]','match');
   data = default(numbers{contains(Header,'start of data')}+1:end);
   numbers =regexp(Header,'[0-9]');
   numbers = cellfun(@(C1,C2) str2num(C1(C2)),Header,numbers,'UniformOutput',false);
end
% Header =cellfun(@join,Header,'UniformOutput',false)';

if ~any(contains(Header,'Time data'))
    disp('does not contain a time signal')
    return
end

nbr_of_chs = numbers{contains(Header,'nbr of channel:')};
nbr_of_abs = numbers{contains(Header,'nbr of abscissa:')};
nbr_of_scans = numbers{contains(Header,'nbr of scans:')};
info = generateInfo(Header,nbr_of_chs,nbr_of_abs);
ch_defs = find(contains(Header,'channel definition:'));
extra_fields = find(contains(Header,'extra fields'));
bits_per_channel = [numbers{contains(Header,'implementation type:')}];

ch_order=regexp(Header{contains(Header,'ch order:')},'[:,]','split');
ch_order = ch_order(2:end); % getting rid of "ch order"

ch_order = cellfun(@strtrim,ch_order,'UniformOutput',false);
% ch_order = cellfun(@(C) C(1:end-2),ch_order,'UniformOutput',false);
ch_order = cellfun(@str2num,ch_order);
ch_order = ch_order./(1:nbr_of_chs);
bytes_per_scan = sum(bits_per_channel.*ch_order)/8;

byte_stream = unicode2native(data(1:nbr_of_scans*bytes_per_scan));
if mod(length(byte_stream),2)
    add = zeros(1,4-mod(length(byte_stream),2));
else
    add =[];
end
byte_stream = [add,byte_stream];

end_idx = cumsum(bits_per_channel.*ch_order)/8;
% ch=cell(nbr_of_chs,1);
ch = zeros(nbr_of_chs,nbr_of_scans);
start_idx = [1,end_idx(1:end-1)+1];

type = Header(contains(Header,'implementation type:'));
type(contains(type,'FLOAT32'))={'single'};
type(contains(type,'UINT32'))={'uint32'};
type(contains(type,'INT16'))={'int16'};

unique_ch_order = unique(ch_order);
if length(unique_ch_order ) ==1
   unique_ch_order =1; 
end
if ~iscell(ch_order)
    if unique_ch_order ~=1
        for single_type=unique(type)
            length_type = unique(bits_per_channel(strcmp(type,single_type)))*nbr_of_scans;
            ch_d.(single_type{1}) = zeros(sum(strcmp(type,single_type)),length_type,single_type{1});
        end
    end
for k=1:nbr_of_scans
    byte_stream_temp = byte_stream((k-1)*bytes_per_scan+1:k*bytes_per_scan);
    for i=1:nbr_of_chs
        if unique_ch_order ==1
            ch(i,(k-1)*ch_order(i)+1:k*ch_order(i))= typecast(byte_stream_temp(start_idx(i):end_idx(i)),type{i});
        else
            ch_d.(type{i})(i,(k-1)*ch_order(i)+1:k*ch_order(i)) = typecast(byte_stream_temp(start_idx(i):end_idx(i)),type{i});
        end
    end
end
else 
    
end
if strcmp(info.scanmode,'synchronised multiple') && exist('ch_d','var')
    if isfield(info.channels,'moniker')
        all_monikers = info.channels.moniker;
        all_monikers = cellfun(@(C)(strrep(C,'.','_')),all_monikers,'UniformOutput',false);
        unique_monikers = unique(all_monikers);
        for moniker = unique_monikers
            timeData.(moniker{1}) = [];
            for channel = 1:nbr_of_chs
                if strcmp(moniker{1},all_monikers{channel})
                    temp = ch_d.(type{channel})(channel,:);
                    timeData.(moniker{1}) = [timeData.(moniker{1}) ;temp];
                end
            end
            if length(unique(ch_order(strcmp(all_monikers,moniker{1})))) == 1
                signalLength = unique(ch_order(strcmp(all_monikers,moniker{1}))) * nbr_of_scans;
                timeData.(moniker{1}) = timeData.(moniker{1})(:,1:signalLength);
            end
        end
    else
        disp('could not find moniker of channels, dumping data');
        timeData = ch_d; 
    end
    
elseif exist('ch_d','var') && strcmp(info.scanmode,'simultaneous')
    temp = fieldnames(ch_d);
    for k=1:length(temp)
        ch_d.(temp{k})( all(~ch_d.(temp{k}),2), : ) = [];
    end
    timeData = ch_d; 
else 
    timeData= ch;
end

end
function info = generateInfo(Header,nbr_of_chs,nbr_of_abs)
    fields =Header(contains(Header,':'));
    field_values = cellfun(@(C)(strtrim(C(strfind(C,':')+1:end))),fields,'UniformOutput',false);
    fields = cellfun(@(C)(strtrim(C(1:strfind(C,':')-1))),fields,'UniformOutput',false);
    
    unique_fields=unique(fields);
    occurences_field=cellfun(@(C)(sum(strcmp(fields,C))),unique_fields,'UniformOutput',false);
    clean_unique_fields = regexp(unique_fields,'[;:#.0-9]','split');
    clean_unique_fields =cellfun(@(C)(strrep(strjoin(C,'_'),' ','')),clean_unique_fields,'UniformOutput',false);
    % clean_unique_fields = cellfun(@(C)(strtok(C)))
    % get rid of double matches in contains leading to non mentioned names
    for k=1:length(occurences_field)
        switch occurences_field{k}
            case 1
                try
                    field = strcat(deal(strtok(clean_unique_fields{k},'_')));
                    info.(field) = field_values{contains(fields,unique_fields{k})};
                catch
                    disp(['"',field,'" is not a valid field name'])
                end
            case nbr_of_chs
                try
                    field = strcat(deal(strtok(clean_unique_fields{k},'_')));
                    info.channels.(field) =  field_values(strcmp(fields,unique_fields{k}));
                catch
                    disp(['"',field,'" is not a valid field name'])
                end
            case (nbr_of_chs + nbr_of_abs)
                try
                    temp = field_values(strcmp(fields,unique_fields{k}));
                    field = strcat(deal(strtok(clean_unique_fields{k})));
    %                 temp = field_values(contains(fields,unique_fields{k}));
                    info.channels.(field) = temp(nbr_of_abs+1:end);
                    info.absc.(field) = temp(1:nbr_of_abs);
                catch
                    try
                        field = strrep(clean_unique_fields{k},'_','');
                        info.channels.(field) = temp(nbr_of_abs+1:end);
                        info.absc.(field) = temp(1:nbr_of_abs);
                    catch
                        disp(['"',field,'" is not a valid field name'])
                    end
                end
        end
    end
    info.nbr_of_chn = nbr_of_chs;
    info.nbr_of_absc = nbr_of_abs;
end