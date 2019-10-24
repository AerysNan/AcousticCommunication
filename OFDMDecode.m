function [decode_clip, phase] = OFDMDecode(clip, ofdm_length, psk_length, prev)
    n = ofdm_length / psk_length;
    vector = fft(clip);
    vector = vector(1: length(vector) / 2);
    amplitude = abs(vector);
    sorted = sort(amplitude);
    peak_value = sorted(end - n + 1: end);
    index = zeros(1, n);
    decode_clip = zeros(1, ofdm_length);
    phase = zeros(1, n);
    for i = 1: n
        index(i) = find(amplitude == peak_value(i));
    end
    index = sort(index);
    for i = 1: n
        degree = angle(vector(index(i)));
        d = mod(degree - prev(i) + 2 * pi, 2 * pi);
        value = mod(round(d * (2 ^ psk_length) / 2 / pi), 2^ psk_length);
        phase(i) = degree;
        decode_clip((i - 1) * psk_length + 1: i * psk_length) = de2bi(value, psk_length);
    end
end