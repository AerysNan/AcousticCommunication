package com.example.acousticcommunication;

import org.apache.commons.math3.analysis.function.Sin;
import org.apache.commons.math3.complex.Complex;

import java.util.Arrays;

import static com.example.acousticcommunication.Global.SignalLength;

class BandPassFilter {
    private Sin sin;
    private double MinFrequency;
    private double MaxFrequency;
    private double SamplingFrequency;
    private double[] window;

    BandPassFilter(double MinFrequency, double MaxFrequency, double SamplingFrequency) {
        this.MinFrequency = MinFrequency;
        this.MaxFrequency = MaxFrequency;
        this.SamplingFrequency = SamplingFrequency;
        this.sin = new Sin();
        CreateWindow();
    }

    void Filter(Complex[] data, int begin) {
        int N = window.length;
        Complex[] result = new Complex[SignalLength];
        Arrays.fill(result, new Complex(0));
        for (int i = 1; i < N; i++)
            for (int j = 0; j < i; j++)
                result[i - 1] = result[i - 1].add(data[j + begin].multiply(window[N - i + j]));
        for (int i = N - 1; i < SignalLength; i++)
            for (int j = 0; j < N; j++)
                result[i] = result[i].add(data[i + j + begin - N + 1].multiply(window[j]));
        System.arraycopy(result, 0, data, begin, SignalLength);
    }

    private void CreateWindow() {
        int N = (int) Math.round(SignalLength * 0.4);
        window = new double[N];
        double r1 = MinFrequency / SamplingFrequency;
        double r2 = MaxFrequency / SamplingFrequency;
        for (int i = 0; i < N; i++)
            window[N - 1 - i] = Sinc(i - 0.5 * N, r2) - Sinc(i - 0.5 * N, r1);
    }

    private double Sinc(double x, double a) {
        if (x == 0)
            return 2 * a;
        else
            return sin.value(2 * Math.PI * a * x) / Math.PI / x;
    }
}
