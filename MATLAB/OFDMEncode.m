function [output, phase] = OFDMEncode(data, base_frequency, psk_length, ofdm_length, sampling_frequency, signal_length, prev)
    sampling_span = 1 / sampling_frequency;
    signal_time = signal_length / sampling_frequency;
    sampling_point = 0: sampling_span: signal_time - sampling_span;
    output = zeros(1, signal_length);
    phase = zeros(1, ofdm_length / psk_length);
    for j  = 1: psk_length: ofdm_length
        clip_index = (j - 1) / psk_length + 1;
        clip_frequency = base_frequency * clip_index;
        [clip_output, p] = PSKEncode(sampling_point, clip_frequency, data(j: j + psk_length - 1), prev(clip_index));
        output = output + clip_output;
        phase(clip_index) = p;
    end
end