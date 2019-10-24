function output = Carrier(signal, sampling_span, carrier_frequency)
    carrier_point = 0: sampling_span: (length(signal) - 1) * sampling_span;
    output = real(signal) .* cos(2 * pi * carrier_frequency * carrier_point) - imag(signal) .* sin(2 * pi * carrier_frequency * carrier_point);
end