function output = OFDMEncode(data, signal_length, base_frequency, sampling_point, wave_amplitude, psk_length, ofdm_length)
    n = length(data);
    output = zeros(1, signal_length * n / ofdm_length);
    for i = 1: ofdm_length: n
        segment_data = data(i: i + ofdm_length - 1);
        segment_output = zeros(1, signal_length);
        for j = 1: psk_length: ofdm_length
            clip_index = (j - 1) / psk_length + 1;
            clip_frequency = base_frequency * clip_index;
            clip_data = segment_data(j: j + psk_length - 1);
            clip_output = PSKEncode(sampling_point, clip_frequency, wave_amplitude, clip_data);
            segment_output = segment_output + clip_output;
        end
        pos = (i - 1) * signal_length / ofdm_length + 1;
        output(pos: pos + signal_length - 1) = segment_output;
    end
end

