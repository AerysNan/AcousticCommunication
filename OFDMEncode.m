function output = OFDMEncode(data, base_frequency, psk_length, ofdm_length, sampling_frequency, signal_length)
    sampling_span = 1/ sampling_frequency;
    signal_time = signal_length / sampling_frequency;
    sampling_point = 0: sampling_span: signal_time - sampling_span;
    output = zeros(1, signal_length);
    for j   = 1: psk_length: ofdm_length
        clip_index = (j - 1) / psk_length + 1;
        clip_frequency = base_frequency * clip_index;
        clip_output = PSKEncode(sampling_point, clip_frequency, data(j: j + psk_length - 1));
        output = output + clip_output;
    end
end