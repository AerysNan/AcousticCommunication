function output = Carrier(signal_baseband, sampling_span, carrier_amplitude, carrier_frequency)
    carrier_point = 0: sampling_span: (length(signal_baseband) - 1) * sampling_span;
    carrier_wave = carrier_amplitude * cos(2 * pi * carrier_frequency * carrier_point);
    output = signal_baseband .* carrier_wave;
end

