close all;
clear;
clc;

simulate = input("Run in simulate mode: ");
%% anaSound
base_frequency = 500;
signal_length = 882;
header_length = 32;
signal_real_length = signal_length + header_length;
sampling_frequency = 44100;
signal_time = signal_real_length / sampling_frequency;
sampling_span = 1 / sampling_frequency;
psk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits
carrier_frequency = 5000;
check_length = ofdm_length;

chirp_u_time = 0.02;
chirp_u_begin_frequency = 200;
chirp_u_end_frequency = 600;
chirp_d_time = 0.01;
chirp_d_begin_frequency = 600;
chirp_d_end_frequency = 1000;
signal_u_chirp = chirp(0: sampling_span: chirp_u_time - sampling_span, chirp_u_begin_frequency, chirp_u_time, chirp_u_end_frequency);
signal_d_chirp = chirp(0: sampling_span: chirp_d_time - sampling_span, chirp_d_begin_frequency, chirp_d_time, chirp_d_end_frequency);

if simulate
    soundFile = 'output.wav';
    [signal_received, ~] = audioread(soundFile);
    signal_received = awgn(signal_received, 10);
    signal_received = signal_received(:, 1);
    signal_received = signal_received';
    signal_received = signal_received(1 + length(signal_u_chirp): end - length(signal_d_chirp));
else
    soundFile = 'received.wav';
    [signal_received, ~] = audioread(soundFile);
    signal_received = signal_received(:, 1);
    signal_received = signal_received';
    [C, lag] = xcorr(signal_received, signal_u_chirp);
    [~, I] = max(C);
    begin = lag(I) + length(signal_u_chirp);
    signal_received = signal_received(begin: end);
    [C, lag] = xcorr(signal_received, signal_d_chirp);
    [~, I] = max(C);
    finish = round(lag(I) / signal_real_length) * signal_real_length;
    signal_received = signal_received(1: finish);
end

content_time = signal_time * length(signal_received) / signal_real_length;
offset_frequency = 10;
max_frequency = base_frequency * ofdm_length / psk_length;

plot(0: sampling_span: content_time - sampling_span, signal_received, "LineWidth", 0.5);
xlabel("Time");
ylabel("Received Signal");
grid on;

%% decode
decode_data = zeros(1, ofdm_length * length(signal_received) / signal_real_length);
signal_received = Carrier(signal_received, sampling_span, carrier_frequency);
phase = repmat(pi / 4, 1, ofdm_length / psk_length);
for i = 1: signal_real_length: length(signal_received)
    clip = signal_received(i + header_length: i + signal_real_length - 1);
    clip_filtered = BPassFilter(clip, base_frequency - offset_frequency, max_frequency + offset_frequency, sampling_frequency);
    [decode_clip, phase] = OFDMDecode(clip_filtered, ofdm_length, psk_length, phase);
    pos = (i - 1) * ofdm_length / signal_real_length + 1;
    decode_data(pos: pos + ofdm_length - 1) = decode_clip;
end

decode_data = decode_data(1 + check_length: end);


disp(decode_data);