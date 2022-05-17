aheader = xml2struct('aheader.xml');
theader = xml2struct('theader.xml');
%%
for k = 1:24
raw_values{k} =theader.theader.channel_group{1, 1}.data_group{1, 1}.channels.normal{1, k}.raw_values_type.Text  ;
end

%%
fileName ='220315_hb_01_Geely_DCT260_Abnormal noise_1G_LOT_001 19.15 - 23.56s.hdf';
default = fileread(fileName);

%%
values_per_block =str2double(theader.theader.channel_group{1, 1}.data_group{1, 1}.segment_layout.values_per_block.Text);
scan_size = str2double(theader.theader.channel_group{1, 1}.data_group{1, 1}.segment_layout.scan_size.Text);
duration = seconds(datetime(theader.theader.stoptime.Text,'InputFormat','yyyyMMddHHmmssSSSSSS')-datetime(theader.theader.starttime.Text,'InputFormat','yyyyMMddHHmmssSSSSSS'));

%%
nbr_of_scans = 10;
bytes_per_scan = 24*1024;
byte_stream = default(8:end);
nbr_of_chs = 24;
unique_ch_order = 1;
start_idx = str2double(theader.theader.channel_group{1, 1}.data_group{1, 1}.segment_layout.block_offsets  );
end_idx = str2double(theader.theader.channel_group{1, 1}.data_group{1, 1}.segment_layout.block_offsets  )+1024;
type = raw_values;
for k=1:nbr_of_scans
    byte_stream_temp = byte_stream((k-1)*bytes_per_scan+1:k*bytes_per_scan);
    for i=1:nbr_of_chs
        if unique_ch_order ==1
            ch(i,(k-1)*ch_order(i)+1:k*ch_order(i))= typecast(byte_stream_temp(start_idx(i):end_idx(i)),type{i});
        else
            ch_d.(type{i})(i,(k-1)*ch_order(i)+1:k*ch_order(i))= typecast(byte_stream_temp(start_idx(i):end_idx(i)),type{i});
        end
    end
end
%%
fileName = 'Test Signal 16(100Hz noise).hdf';
test = importHDF(fileName);
