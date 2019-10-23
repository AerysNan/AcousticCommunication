function output = PSKEncode(t, frequency, amplitude, data)
    psk_length = length(data);
    n = 2 ^ psk_length; 
    value = bi2de(data);
    wave_cos = amplitude * cos(2 * pi * frequency * t);
    wave_sin = amplitude * sin(2 * pi * frequency * t);
    output = wave_cos * cos((2 * value + 1) / n * pi) - wave_sin * sin((2 * value + 1) / n * pi);
end