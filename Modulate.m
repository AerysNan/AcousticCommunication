close all;
clear;
clc;

%% encode
base_frequency = 1000;
signal_length = 882;
header_length = 32;
signal_real_length = signal_length + header_length;
sampling_frequency = 44100;
signal_time = signal_real_length / sampling_frequency;
sampling_span = 1 / sampling_frequency;
psk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits
carrier_frequency = 10000;
check_length = ofdm_length;

data = [0 0 0 1 1 0 1 1];
data = repmat(data, 1, 10);
check = zeros(1, check_length);
data = [check data];
disp(data);
signal_output = zeros(1, 2 * signal_real_length * length(data) / ofdm_length);
signal_zero = zeros(1, signal_real_length);
phase = repmat(pi / 4, 1, ofdm_length / psk_length);
for i = 1: ofdm_length: length(data)
    [signal_clip, phase] = OFDMEncode(data(i: i + ofdm_length - 1), base_frequency, psk_length, ofdm_length, sampling_frequency, signal_length, phase);
    signal_clip = [signal_clip(end - header_length + 1: end) signal_clip];
    signal_clip = Carrier(signal_clip, sampling_span, carrier_frequency);
    pos = (i - 1) / ofdm_length;
    signal_output(2 * pos * signal_real_length + 1: 2 * (pos + 1) * signal_real_length) = [signal_clip signal_zero];
end
signal_output = signal_output / max(abs(signal_output));

content_time = length(data) / ofdm_length * signal_time * 2;

chirp_u_time = 0.2;
chirp_u_begin_frequency = 200;
chirp_u_end_frequency = 600;
chirp_d_time = 0.1;
chirp_d_begin_frequency = 600;
chirp_d_end_frequency = 1000;
signal_u_chirp = chirp(0: sampling_span: chirp_u_time - sampling_span, chirp_u_begin_frequency, chirp_u_time, chirp_u_end_frequency);
signal_d_chirp = chirp(0: sampling_span: chirp_d_time - sampling_span, chirp_d_begin_frequency, chirp_d_time, chirp_d_end_frequency);

zero_time = 0.1;
signal_zero = zeros(1, zero_time * sampling_frequency);
signal_output = [signal_u_chirp signal_output signal_d_chirp];

total_time = content_time + chirp_u_time + chirp_d_time;
plot(0: sampling_span: total_time - sampling_span, signal_output, "LineWidth", 0.5);
xlabel("Time");
ylabel("Output Signal");
grid on;

%% genSound
soundFile = 'output.wav';
audiowrite(soundFile, signal_output, sampling_frequency, 'BitsPerSample', 16);