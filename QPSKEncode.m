function output = QPSKEncode(t, frequency, amplitude, data)
    value_cos = amplitude * cos(2 * pi * frequency * t);
    value_sin = amplitude * sin(2 * pi * frequency * t);
    encode_table = [1 -1; -1 -1; -1 1; 1 1];
    params = encode_table(data(1) * 2 + data(2) + 1, :);
    output = sqrt(2) / 2 * (params(1) * value_cos + params(2) * value_sin);
end