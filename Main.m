close all;
clear;

%% encode

wave_amplitude = 100;
base_frequency = 100;
sampling_frequency = base_frequency * 100;
sampling_span = 1 / sampling_frequency;
signal_length = 5000;

sampling_point = 0: sampling_span: (signal_length - 1) * sampling_span;
data = [0 0 0 1 1 0 1 1 1 1 1 0 0 1 0 0];

qpsk_length = 2; % qpsk encode per 2 bits
ofdm_length = 8; % ofdm encode per 8 bits
n = length(data);
signal_baseband = zeros(1, signal_length * n / ofdm_length);
for i = 1: ofdm_length: n
    segment_data = data(i: i + ofdm_length - 1);
    segment_output = zeros(1, signal_length);
    for j = 1: qpsk_length: ofdm_length
        clip_index = (j - 1) / qpsk_length + 1;
        clip_frequency = base_frequency * clip_index;
        clip_data = segment_data(j: j + qpsk_length - 1);
        clip_output = QPSKEncode(sampling_point, clip_frequency, wave_amplitude, clip_data);
        segment_output = segment_output + clip_output;
    end
    pos = (i - 1) * signal_length / ofdm_length + 1;
    signal_baseband(pos: pos + signal_length - 1) = segment_output;
end

carrier_frequency = 2000;
carrier_amplitude = 10;
carrier_point = 0: sampling_span: (length(signal_baseband) - 1) * sampling_span;
carrier_wave = carrier_amplitude * cos(2 * pi * carrier_frequency * carrier_point);
signal_output = signal_baseband .* carrier_wave;

figure(1);
subplot(2, 1, 1);
plot(carrier_point, signal_baseband, "LineWidth", 0.5);
xlabel("Time");
ylabel("Baseband Signal");
grid on;

subplot(2, 1, 2);
plot(carrier_point, signal_output, "LineWidth", 0.5);
xlabel("Time");
ylabel("Output Signal");
grid on;

%% decode

signal_received = awgn(signal_output, 5);

figure(2);
subplot(2, 1, 1);
plot(carrier_point, signal_received, "LineWidth", 0.5);
xlabel("Time");
ylabel("Received Signal");
grid on;

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

subplot(2, 1, 2);
plot(carrier_point, signal_filtered, "LineWidth", 0.5);
xlabel("Time");
ylabel("Filtered Signal");
grid on;

disp(decode_data);