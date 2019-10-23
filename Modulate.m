close all;
clear;
clc;

%% encode
wave_amplitude = 1;
base_frequency = 1000;
sampling_frequency = 44100;
signal_time = 0.2;
sampling_span = 1 / sampling_frequency;
signal_length = sampling_frequency * signal_time;
header_length = 24; % maximum length 2^24 bit = 2 Mb

sampling_point = 0: sampling_span: signal_time - sampling_span;
data = [0 0 0 1 1 0 1 1 1 1 1 0 0 1 0 0];
data = [data data data data];
disp(data);

psk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits
signal_baseband = OFDMEncode(data, signal_length, base_frequency, sampling_point, wave_amplitude, psk_length, ofdm_length);

carrier_frequency = 10000;
carrier_amplitude = 1;
signal_output = Carrier(signal_baseband, sampling_span, carrier_amplitude, carrier_frequency);
signal_output = signal_output / max(abs(signal_output));

content_time = length(data) / ofdm_length * signal_time;
figure(1);
subplot(2, 1, 1);
plot(0: sampling_span: content_time - sampling_span, signal_baseband, "LineWidth", 0.5);
xlabel("Time");
ylabel("Baseband Signal");

chirp_time = 0.1;
chirp_frequency = 1000;
chirp_x_axis = 0: sampling_span: chirp_time - sampling_span;
signal_u_chirp = chirp(chirp_x_axis, 0, chirp_time, chirp_frequency);
signal_d_chirp = chirp(chirp_x_axis, 0, chirp_time * 2, chirp_frequency / 2);

zero_time = 0.1;
signal_zero = zeros(1, zero_time * sampling_frequency);
signal_output = [signal_u_chirp signal_zero signal_output signal_zero signal_d_chirp];

total_time = content_time + 2 * chirp_time + 2 * zero_time;
subplot(2, 1, 2);
plot(0: sampling_span: total_time - sampling_span, signal_output, "LineWidth", 0.5);
xlabel("Time");
ylabel("Output Signal");
grid on;

%% genSound
soundFile = 'output.wav';
audiowrite(soundFile, signal_output, sampling_frequency, 'BitsPerSample', 16);