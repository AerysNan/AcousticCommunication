function output = PSKEncode(t, frequency, data)
    psk_length = length(data);
    n = 2 ^ psk_length; 
    value = bi2de(data);
    wave_cos = cos(2 * pi * frequency * t);
    wave_sin = sin(2 * pi * frequency * t);
    output = exp(1i * (2 * pi * frequency * t + (2 * value + 1) / n * pi));
end