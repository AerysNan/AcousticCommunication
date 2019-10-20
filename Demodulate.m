close all;
clear;
clc;

simulate = 1;
%% anaSound

signal_time = 0.2;
sampling_frequency = 44100;
sampling_span = 1 / sampling_frequency;
signal_length = sampling_frequency * signal_time;
base_frequency = 400;
header_length = 24; % maximum length 2^24 bit = 2 Mb
carrier_frequency = 5000;
carrier_amplitude = 1;

psk_length = 1; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits

chirp_time = 0.1;
chirp_frequency = 1000;
chirp_x_axis = 0: sampling_span: chirp_time - sampling_span;
signal_chirp = chirp(chirp_x_axis, 0, chirp_time, chirp_frequency);

zero_time = 0.1;
signal_zero = zeros(1, zero_time * sampling_frequency);
signal_baseband = zeros(35280, 1);
    
if simulate
    soundFile = 'output.wav';
    [signal_output, ~] = audioread(soundFile);
    signal_received = awgn(signal_output, 10);
    signal_received = signal_received';
    begin = 0;
else
    soundFile = 'received.wav';
    [signal_received, fs] = audioread(soundFile);
    signal_received = signal_received(:, 1);
    signal_received = signal_received';
    [C,lag] = xcorr(signal_received, signal_chirp);
    [~, I] = max(C);
    begin = lag(I);
end

header_count = header_length / ofdm_length * signal_length;
header = signal_received(begin + length(signal_chirp) + length(signal_zero):...
    begin + length(signal_chirp) + length(signal_zero) + header_count);
header_adjusted = Carrier(header, sampling_span, carrier_amplitude, carrier_frequency);
decode_header = zeros(1, header_length);
offset_frequency = 10;
max_frequency = base_frequency * ofdm_length / psk_length;
for i = 1: signal_length: header_count
    clip = header_adjusted(i: i + signal_length - 1);
    clip_filtered = BPassFilter(clip, base_frequency - offset_frequency, max_frequency + offset_frequency, sampling_frequency);
    decode_clip = OFDMDecode(clip_filtered, ofdm_length, psk_length);
    pos = (i - 1) * ofdm_length / signal_length + 1;
    decode_header(pos: pos + ofdm_length - 1) = decode_clip;
end

content_length = bi2de(decode_header);
content_time = content_length / ofdm_length * signal_time;
offset = header_count + length(signal_zero) + length(signal_chirp);
signal_received = signal_received(begin + offset: begin + offset + content_length / ofdm_length * signal_length - 1);

plot(0: sampling_span: content_time - sampling_span, signal_received, "LineWidth", 0.5);
xlabel("Time");
ylabel("Received Signal");
grid on;

%% decode
signal_adjusted = Carrier(signal_received, sampling_span, carrier_amplitude, carrier_frequency);
decode_data = zeros(1, ofdm_length * length(signal_adjusted) / signal_length);

for i = 1: signal_length: length(signal_adjusted)
    clip = signal_adjusted(i: i + signal_length - 1);
    clip_filtered = BPassFilter(clip, base_frequency - offset_frequency, max_frequency + offset_frequency, sampling_frequency);
    decode_clip = OFDMDecode(clip_filtered, ofdm_length, psk_length);
    pos = (i - 1) * ofdm_length / signal_length + 1;
    decode_data(pos: pos + ofdm_length - 1) = decode_clip;
end

disp(decode_data);