function [output, phase] = PSKEncode(t, frequency, data, prev)
    psk_length = length(data);
    n = 2 ^ psk_length;
    value = bi2de(data);
    phase = 2 * value / n * pi + prev;
    output = exp(1i * (2 * pi * frequency * t + phase));
end