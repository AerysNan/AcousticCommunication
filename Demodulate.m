close all;
clear;
clc;

simulate = input("Run in simulate mode: ");
%% anaSound
base_frequency = 500;
signal_length = 882;
sampling_frequency = 44100;
signal_time = signal_length / sampling_frequency;
sampling_span = 1 / sampling_frequency;
carrier_frequency = 10000;
psk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits

chirp_time = 0.1;
chirp_frequency = 1000;
chirp_x_axis = 0: sampling_span: chirp_time - sampling_span;
signal_u_chirp = chirp(chirp_x_axis, 0, chirp_time * 2, chirp_frequency);
signal_d_chirp = chirp(chirp_x_axis, 0, chirp_time, chirp_frequency / 2);

if simulate
    soundFile = 'output.wav';
    [signal_output, ~] = audioread(soundFile);
%    signal_received = signal_output;
    signal_received = awgn(signal_output, 10);
    signal_received = signal_received';
    signal_received = signal_received(1 + length(signal_u_chirp): end - length(signal_d_chirp));
else
    soundFile = 'received.wav';
    [signal_received, fs] = audioread(soundFile);
    signal_received = signal_received';
    [C, lag] = xcorr(signal_received, signal_u_chirp);
    [~, I] = max(C);
    begin = lag(I) + length(signal_u_chirp);
    signal_received = signal_received(begin: end);
    [C, lag] = xcorr(signal_received, signal_d_chirp);
    [~, I] = max(C);
    finish = round(lag(I) / signal_length) * signal_length;
    signal_received = signal_received(1: finish);
end

content_time = signal_time * length(signal_received) / signal_length;
offset_frequency = 10;
max_frequency = base_frequency * ofdm_length / psk_length;

plot(0: sampling_span: content_time - sampling_span, signal_received, "LineWidth", 0.5);
xlabel("Time");
ylabel("Received Signal");
grid on;

%% decode
decode_data = zeros(1, ofdm_length * length(signal_received) / 2 / signal_length);

for i = 1: 2 * signal_length: length(signal_received)
    clip = Carrier(signal_received(i: i + signal_length - 1), sampling_span, carrier_frequency);
    clip_filtered = BPassFilter(clip, base_frequency - offset_frequency, max_frequency + offset_frequency, sampling_frequency);
    decode_clip = OFDMDecode(clip_filtered, ofdm_length, psk_length);
    pos = (i - 1) * ofdm_length / 2 / signal_length + 1;
    decode_data(pos: pos + ofdm_length - 1) = decode_clip;
end

disp(decode_data);