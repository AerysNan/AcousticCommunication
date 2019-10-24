close all;
clear;
clc;

%% encode
base_frequency = 500;
signal_length = 882;
sampling_frequency = 44100;
signal_time = signal_length / sampling_frequency;
sampling_span = 1 / sampling_frequency;
psk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits
carrier_frequency = 10000;

data = [0 0 0 1 1 0 1 1];
data = repmat(data, 1, 5);
disp(data);
signal_output = zeros(1, 2 * signal_length * length(data) / ofdm_length);
signal_zero = zeros(1, signal_length);
for i = 1: ofdm_length: length(data)
    signal_clip = OFDMEncode(data(i: i + ofdm_length - 1), base_frequency, psk_length, ofdm_length, sampling_frequency, signal_length);
    signal_clip = Carrier(signal_clip, sampling_span, carrier_frequency);
    pos = (i - 1) / ofdm_length;
    signal_output(2 * pos * signal_length + 1: 2 * (pos + 1) * signal_length) = [signal_clip signal_zero];
end
signal_output = signal_output / max(abs(signal_output));

content_time = length(data) / ofdm_length * signal_time * 2;

chirp_time = 0.1;
chirp_frequency = 1000;
chirp_x_axis = 0: sampling_span: chirp_time - sampling_span;
signal_u_chirp = chirp(chirp_x_axis, 0, chirp_time * 2, chirp_frequency);
signal_d_chirp = chirp(chirp_x_axis, 0, chirp_time, chirp_frequency / 2);

zero_time = 0.1;
signal_zero = zeros(1, zero_time * sampling_frequency);
signal_output = [signal_u_chirp signal_output signal_d_chirp];

total_time = content_time + 2 * chirp_time;
plot(0: sampling_span: total_time - sampling_span, signal_output, "LineWidth", 0.5);
xlabel("Time");
ylabel("Output Signal");
grid on;

%% genSound
soundFile = 'output.wav';
audiowrite(soundFile, signal_output, sampling_frequency, 'BitsPerSample', 16);