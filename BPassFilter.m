% data: input signal
% centerFre: center frequency
% offsetFre: frequency bandwidth
% sampFre: sampling frequency

function y = BPassFilter(data, min_frequency, max_frequency, sample_frequency)
    Wp1 = min_frequency / sample_frequency;  % minimum
    Wp2 = max_frequency / sample_frequency;  % maximum
    N = round(length(data) * 0.4);
    h = zeros(1, N);
    for k = 1: N
        h(k) = Sinc(k - 1 - 0.5 * N, Wp2) - Sinc(k - 1 - 0.5 * N, Wp1);
    end
  y = filter(h, 1, data);
end