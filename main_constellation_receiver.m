% use with /home/guyu/my_gnuradio_projects/cma/verify_block2.grc
% attention: since packet_encoder do whitening, as a result, the txt should
% be compared with the output of packet_encoder block.

% conclusion: GNU Radio's constellation_receiver performs better because of
% two set_msg_handler

% guyu all rights reservered

clc;close all;clear;

% flowchart
disp('process: constellation_receiver -> diff_decoder -> map -> unpack_k_bits')

%% data
data_length=20000;

simu_flag=1;
if simu_flag==1
    filename='/home/guyu/USRP_MATLAB/polyrate filter bank/pfb_clock_sync/pfb_clock_sync_out.bin';
    [fid]=fopen(filename,'rb');
    input=fread(fid,2*data_length,'float32');
    input=input(1:2:end)+1i*input(2:2:end);
    fclose(fid);
    
    filename='constellation_receiver_out.bin';
    [fid]=fopen(filename,'rb');
    output_verify=fread(fid,data_length,'uint8');
    fclose(fid);
    
    filename='phase_error.bin';
    [fid]=fopen(filename,'rb');
    phase_error_rec_verify=fread(fid,data_length,'float32');
    fclose(fid);
    
    filename='d_phase.bin';
    [fid]=fopen(filename,'rb');
    d_phase_rec_verify=fread(fid,data_length,'float32');
    fclose(fid);
    
    filename='d_freq.bin';
    [fid]=fopen(filename,'rb');
    d_freq_rec_verify=fread(fid,data_length,'float32');
    fclose(fid);
    
    filename='sample.bin';
    [fid]=fopen(filename,'rb');
    sample_rec_verify=fread(fid,2*data_length,'float32');
    sample_rec_verify=sample_rec_verify(1:2:end)+1i*sample_rec_verify(2:2:end);
    fclose(fid);
else
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_pfb.bin';
    [fid]=fopen(filename,'rb');
    input=fread(fid,2*data_length,'float32');
    input=input(1:2:end)+1i*input(2:2:end);
    fclose(fid);
    
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_constellation_out.bin';
    [fid]=fopen(filename,'rb');
    output_verify=fread(fid,data_length,'uint8');
    fclose(fid);
    
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_constel_error.bin';
    [fid]=fopen(filename,'rb');
    phase_error_rec_verify=fread(fid,data_length,'float32');
    fclose(fid);
    
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_constel_phase.bin';
    [fid]=fopen(filename,'rb');
    d_phase_rec_verify=fread(fid,data_length,'float32');
    fclose(fid);
    
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_constel_f.bin';
    [fid]=fopen(filename,'rb');
    d_freq_rec_verify=fread(fid,data_length,'float32');
    fclose(fid);
    
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_constel_symbol.bin';
    [fid]=fopen(filename,'rb');
    sample_rec_verify=fread(fid,2*data_length,'float32');
    sample_rec_verify=sample_rec_verify(1:2:end)+1i*sample_rec_verify(2:2:end);
    fclose(fid);
end

%% constellation_receiver
[out_constellation_receiver,phase_error_rec,d_phase_rec,d_freq_rec,sample_rec]=constellation_receiver(input);

if isempty(find(abs(sample_rec-[input(1);exp(1i*d_phase_rec(1:end-1)).*input(2:end)])>0.0001))
    disp('sample_rec = exp(1i*d_phase)*input')
else
    disp('attention: sample_rec ~= exp(1i*d_phase)*input')
end
if isempty(find(abs(sample_rec_verify-[input(1);exp(1i*d_phase_rec_verify(1:end-1)).*input(2:end)])>0.0001))
    disp('sample_rec_verify = exp(1i*d_phase_verify)*input')
else
    disp('attention: sample_rec_verify ~= exp(1i*d_phase_verify)*input')
end
if isequal(out_constellation_receiver,output_verify)
    disp('the output of my constellation_receiver is the same as GNU Radio!');
    if isempty(find(abs(d_phase_rec-d_phase_rec_verify)>0.001))
        disp('my constellation_receiver is similar to GNU Radio!');
    end
else
    disp('attention: my constellation_receiver is different from GNU Radio, but it does not matter because of diff, if diff is still different, it will be a problem!');
end

%% part 1: using output_verify %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% diff_decoder_bb
modulus=4;
out_diff_decoder_bb_verify=diff_decoder_bb(output_verify,modulus);

%% map
for i=1:length(out_diff_decoder_bb_verify)
    if out_diff_decoder_bb_verify(i)==2
        out_diff_decoder_bb_verify(i)=3;
    elseif out_diff_decoder_bb_verify(i)==3
        out_diff_decoder_bb_verify(i)=2;
    end
end

%% unpack_k_bits
k=2;
out_unpack_k_bits_verify=unpack_k_bits(out_diff_decoder_bb_verify, k);

%% correlate_access_code
if simu_flag
    filename='unpack_k_bits_out.bin';
    [fid]=fopen(filename,'rb');
    txt_bits=fread(fid,2*data_length,'uint8');
    fclose(fid);
else
    filename='/home/guyu/my_gnuradio_projects/cma/cma_test_unpack.bin';
    [fid]=fopen(filename,'rb');
    txt_bits=fread(fid,2*data_length,'uint8');
    fclose(fid);
end

% verification of diff_decoder_bb, map & unpack_k_bits
if isempty(find(out_unpack_k_bits_verify~=txt_bits,1))
    disp('diff_decoder_bb, map & unpack_k_bits are the same as GNU Radio!')
else
    disp('attention: diff_decoder_bb, map & unpack_k_bits are different from GNU Radio!')
end

%
threshold=-1;
packet_start_verify = correlate_access_code(out_unpack_k_bits_verify, threshold);

%% BER (Bit Error Ratio)
if simu_flag
    filename='packet_encoder_out.bin';
    [fid]=fopen(filename,'rb');
    packet_encoder_out=fread(fid,144,'uint8');
    fclose(fid);
    packet_encoder_out_bit=unpack_k_bits(packet_encoder_out, 8);
else
    filename='/home/guyu/Documents/GNURADIO/temp.bin';
    [fid]=fopen(filename,'rb');
    packet_encoder_out=fread(fid,528,'uint8');
    fclose(fid);
    packet_encoder_out_bit=unpack_k_bits(packet_encoder_out, 8);
    
end


ber=zeros(length(out_unpack_k_bits_verify)-length(packet_encoder_out_bit)+1,1);
for i=1:length(out_unpack_k_bits_verify)-length(packet_encoder_out_bit)+1
    ber(i)=sum(out_unpack_k_bits_verify(i:i+length(packet_encoder_out_bit)-1)==packet_encoder_out_bit)/length(packet_encoder_out_bit);
end
figure
plot(ber)
title('ber (because of whitening, only the first peak is correct)')

% bin2hex for a better view
n_byte=floor((length(out_unpack_k_bits_verify)-packet_start_verify(1)+1)/8);
txt=cell(n_byte,1);
for i=1:n_byte
    temp='';
    for j=0:7
        temp=strcat(temp,dec2bin(out_unpack_k_bits_verify(packet_start_verify(1)+8*i-8+j),1));
    end
    txt{i}=dec2hex(bin2dec(temp),2);
end

% equivalent to threshold=0
% default_access_code='\xAC\xDD\xA4\xE2\xF2\x8C\x20\xFC'
% default_preamble='\xA4\xF2'
for i=1:length(txt)-9
    if isequal(txt{i},'A4') && isequal(txt{i+1},'F2')
        if isequal(txt{i+2},'AC') && isequal(txt{i+3},'DD') && isequal(txt{i+4},'A4') && isequal(txt{i+5},'E2') && isequal(txt{i+6},'F2') && isequal(txt{i+7},'8C') && isequal(txt{i+8},'20') && isequal(txt{i+9},'FC')
            i;
        end
    end
end


%% part 2: using out_constellation_receiver %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% diff_decoder_bb
modulus=4;
out_diff_decoder_bb=diff_decoder_bb(out_constellation_receiver,modulus);

%% map
for i=1:length(out_diff_decoder_bb)
    if out_diff_decoder_bb(i)==2
        out_diff_decoder_bb(i)=3;
    elseif out_diff_decoder_bb(i)==3
        out_diff_decoder_bb(i)=2;
    end
end

if isequal(out_diff_decoder_bb,out_diff_decoder_bb_verify)
    disp('my out_diff_decoder_bb is the same as GNU Radio!');
else
    error('attention: my out_diff_decoder_bb is different from GNU Radio, try to find the problem! (decision_maker_pe)');
end

%% unpack_k_bits
out_unpack_k_bits=unpack_k_bits(out_diff_decoder_bb, k);

%% correlate_access_code
packet_start = correlate_access_code(out_unpack_k_bits, threshold);

%% BER (Bit Error Ratio)
ber_1=zeros(length(out_unpack_k_bits)-length(packet_encoder_out_bit)+1,1);
for i=1:length(out_unpack_k_bits)-length(packet_encoder_out_bit)+1
    ber_1(i)=sum(out_unpack_k_bits(i:i+length(packet_encoder_out_bit)-1)==packet_encoder_out_bit)/length(packet_encoder_out_bit);
end
figure
plot(ber_1)
title('my constellation ber (because of whitening, only the first peak is correct)')

%% part3: xls write
% label={'phase_error_rec','phase_error_rec_verify','d_phase_rec','d_phase_rec_verify','d_freq_rec','d_freq_rec_verify','sample_rec','sample_rec_verify','input'};
% xlswrite('constellation_receiver.xlsx',label,'A1:I1')
% xlswrite('constellation_receiver.xlsx',[phase_error_rec,phase_error_rec_verify,d_phase_rec,d_phase_rec_verify,d_freq_rec,d_freq_rec_verify,sample_rec,sample_rec_verify,input],'A2')

%% part4: appendix

