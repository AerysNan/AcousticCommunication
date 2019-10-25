function output = DeCarrier(signal, sampling_span, carrier_frequency)
    carrier_point = 0: sampling_span: (length(signal) - 1) * sampling_span;
    output = signal .* cos(2 * pi * carrier_frequency * carrier_point) - 1i * signal .* sin(2 * pi * carrier_frequency * carrier_point);
end