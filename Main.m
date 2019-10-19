close all;
clear;
clc;

%% encode

wave_amplitude = 100;
base_frequency = 100;
sampling_frequency = base_frequency * 100;
sampling_span = 1 / sampling_frequency;
signal_length = 5000;

sampling_point = 0: sampling_span: (signal_length - 1) * sampling_span;
preamble = [0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1];
data = [0 0 0 1 1 0 1 1 1 1 1 0 0 1 0 0];
data = [data, data, data, data];

qpsk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits

signal_baseband_preamble = OFDM(preamble, signal_length, base_frequency,...
    sampling_point,wave_amplitude, qpsk_length, ofdm_length);

signal_baseband = OFDM(data, signal_length, base_frequency, ...
    sampling_point,wave_amplitude, qpsk_length, ofdm_length);


carrier_frequency = 2000;
carrier_amplitude = 10;
carrier_point = 0: sampling_span: (length(signal_baseband) - 1) * sampling_span;
carrier_wave = carrier_amplitude * cos(2 * pi * carrier_frequency * carrier_point);
% signal_output = signal_baseband .* carrier_wave;
signal_output = Carrier(signal_baseband, sampling_span, ...
    carrier_amplitude, carrier_frequency);

signal_output_preamble = Carrier(signal_baseband_preamble, ...
    sampling_span, carrier_amplitude, carrier_frequency);




figure(1);
subplot(2, 1, 1);
plot(carrier_point, signal_baseband, "LineWidth", 0.5);
xlabel("Time");
ylabel("Baseband Signal");

%signal_output = signal_output / max(signal_output);
signal_output = mapminmax(signal_output); %normalization to [-1.0, 1.0]
signal_output_preamble = mapminmax(signal_output_preamble); %normalization to [-1.0, 1.0]
signal_zeros = zeros(1, 10000);
signal_preamble = [signal_zeros, signal_output_preamble, signal_zeros];

signal_output = [signal_preamble, signal_output];

subplot(2, 1, 2);
plot(signal_output, "LineWidth", 0.5);
xlabel("Time");
ylabel("Output Signal");
grid on;

%signal_received = awgn(signal_output, 5);

%% genSound
fs = 44100;
soundFile = 'genSound.wav';

audiowrite(soundFile, signal_output, fs, 'BitsPerSample', 16);
%sound(signal_output, fs);

%% anaSound
soundFile = 'receivedSound.wav';

[signal_received, fs] = audioread(soundFile);
signal_received = signal_received';

%% insert blank of recording
% signal_blank = rand(1, 10234)*2-1;
% signal_received = [signal_blank, signal_received, signal_blank];

figure(2);
subplot(3, 1, 1);
plot(signal_received, "LineWidth", 0.5);
xlabel("Time");
ylabel("Received Signal");
grid on;

%% acquire the target signal's position
[C21,lag21] = xcorr(signal_received, signal_output_preamble);
C21 = C21/max(C21);
[~, I21] = max(C21);
t21 = lag21(I21)-1000;

signal_received = signal_received(t21 : end);

%% second align
[C21,lag21] = xcorr(signal_received, signal_output_preamble);
C21 = C21/max(C21);
[~, I21] = max(C21);
t21 = lag21(I21)+20001;

signal_received = signal_received(t21 : t21+length(carrier_wave)-1);


subplot(3, 1, 2);
plot(signal_received, "LineWidth", 0.5);
xlabel("Time");
ylabel("Received Signal");
grid on;



%% decode
offset_frequency = 10;
signal_adjusted = signal_received .* carrier_wave;
signal_filtered = zeros(1, length(signal_adjusted));
max_frequency = base_frequency * ofdm_length / qpsk_length;
decode_data = zeros(1, ofdm_length * length(signal_filtered) / signal_length);
decode_table = [0 0; 0 1; 1 0; 1 1];

for i = 1: signal_length: length(signal_adjusted)
    clip = signal_adjusted(i: i + signal_length - 1);
    clip_filtered = BPassFilter(clip, base_frequency - offset_frequency, max_frequency + offset_frequency, sampling_frequency);
    signal_filtered(i: i + signal_length - 1) = clip_filtered;
    frequency_domain = fft(clip_filtered);
    frequency_domain = frequency_domain(1: length(frequency_domain) / 2);
    max_amplitude = max(abs(frequency_domain));
    index = find(abs(frequency_domain) > max_amplitude * 0.8);
    signal_angle = angle(frequency_domain(index));
    phase = round(mod(signal_angle, 2 * pi) * 4 / pi);
    decode_clip = decode_table((phase - 1) / 2 + 1, :);
    decode_clip = reshape(decode_clip', 1, ofdm_length);
    pos = (i - 1) * ofdm_length / signal_length + 1;
    decode_data(pos: pos + ofdm_length - 1) = decode_clip;
end

subplot(3, 1, 3);
plot(signal_filtered, "LineWidth", 0.5);
xlabel("Time");
ylabel("Filtered Signal");
grid on;

disp(decode_data);