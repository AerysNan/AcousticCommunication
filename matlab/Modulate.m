close all;
clear;
clc;

%% encode
base_frequency = 400;
signal_length = 1024;
header_length = 32;
signal_real_length = signal_length + header_length;
sampling_frequency = 40960;
signal_time = signal_real_length / sampling_frequency;
sampling_span = 1 / sampling_frequency;
psk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits
carrier_frequency = 5000;
check_length = ofdm_length;

message = 'Hello World!';
data = de2bi(double(message), ofdm_length);
data = reshape(data.', 1, []);

header = zeros(1, check_length);
data = [header data];
disp(data);
signal_output = zeros(1, signal_real_length * length(data) / ofdm_length);
phase = repmat(pi / 4, 1, ofdm_length / psk_length);
for i = 1: ofdm_length: length(data)
    [signal_clip, phase] = OFDMEncode(data(i: i + ofdm_length - 1), base_frequency, psk_length, ofdm_length, sampling_frequency, signal_length, phase);
    signal_clip = [signal_clip(end - header_length + 1: end) signal_clip];
    pos = (i - 1) / ofdm_length;
    signal_output(pos * signal_real_length + 1: (pos + 1) * signal_real_length) = signal_clip;
end

signal_output = Carrier(signal_output, sampling_span, carrier_frequency);
signal_output = signal_output / max(abs(signal_output));

content_time = length(data) / ofdm_length * signal_time;

chirp_u_length = 1024;
chirp_u_time = chirp_u_length / sampling_frequency;
chirp_u_begin_frequency = 200;
chirp_u_end_frequency = 600;
chirp_d_length = 512;
chirp_d_time = chirp_d_length / sampling_frequency;
chirp_d_begin_frequency = 600;
chirp_d_end_frequency = 1000;
signal_u_chirp = chirp(0: sampling_span: chirp_u_time - sampling_span, chirp_u_begin_frequency, chirp_u_time, chirp_u_end_frequency);
signal_d_chirp = chirp(0: sampling_span: chirp_d_time - sampling_span, chirp_d_begin_frequency, chirp_d_time, chirp_d_end_frequency);

signal_output = [signal_u_chirp signal_output signal_d_chirp];

total_time = content_time + chirp_u_time + chirp_d_time;
plot(0: sampling_span: total_time - sampling_span, signal_output, "LineWidth", 0.5);
xlabel("Time");
ylabel("Output Signal");
grid on;

%% genSound
soundFile = 'output.wav';
audiowrite(soundFile, signal_output, sampling_frequency, 'BitsPerSample', 16);