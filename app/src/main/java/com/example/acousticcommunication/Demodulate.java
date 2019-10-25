package com.example.acousticcommunication;

import org.apache.commons.math3.analysis.function.Cos;
import org.apache.commons.math3.analysis.function.Sin;
import org.apache.commons.math3.complex.Complex;
import org.apache.commons.math3.transform.DftNormalization;
import org.apache.commons.math3.transform.FastFourierTransformer;
import org.apache.commons.math3.transform.TransformType;

import java.util.Arrays;

import static com.example.acousticcommunication.Global.BaseFrequency;
import static com.example.acousticcommunication.Global.CPLength;
import static com.example.acousticcommunication.Global.CarrierFrequency;
import static com.example.acousticcommunication.Global.HeadChirpBeginFrequency;
import static com.example.acousticcommunication.Global.HeadChirpEndFrequency;
import static com.example.acousticcommunication.Global.HeadChirpLength;
import static com.example.acousticcommunication.Global.OFDMLength;
import static com.example.acousticcommunication.Global.OffsetFrequency;
import static com.example.acousticcommunication.Global.PSKLength;
import static com.example.acousticcommunication.Global.SamplingRate;
import static com.example.acousticcommunication.Global.SignalLength;
import static com.example.acousticcommunication.Global.SignalRealLength;
import static com.example.acousticcommunication.Global.TailChirpBeginFrequency;
import static com.example.acousticcommunication.Global.TailChirpEndFrequency;
import static com.example.acousticcommunication.Global.TailChirpLength;
import static com.example.acousticcommunication.Global.DecimalToBitArray;
import static com.example.acousticcommunication.Global.BitArrayToString;

class Demodulate {
    private static Cos cos = new Cos();
    private static Sin sin = new Sin();
    private static BandPassFilter filter;
    private static FastFourierTransformer fastFourierTransformer = new FastFourierTransformer(DftNormalization.STANDARD);

    static String Decode(double[] data) {
        double[] beginChirp = Chirp(HeadChirpBeginFrequency, HeadChirpEndFrequency, HeadChirpLength);
        int beginIndex = ShiftPosition(data, 0, beginChirp) + HeadChirpLength;
        double[] endChirp = Chirp(TailChirpBeginFrequency, TailChirpEndFrequency, TailChirpLength);
        int endIndex = ShiftPosition(data, HeadChirpLength, endChirp);
        endIndex = beginIndex + Math.round((endIndex - beginIndex) / SignalRealLength) * SignalRealLength;
        int signalCount = (endIndex - beginIndex) / SignalRealLength;
        boolean[] decoded = new boolean[signalCount * OFDMLength];
        OFDMDecode(data, beginIndex, endIndex, decoded);
        return BitArrayToString(decoded);
    }

    private static void OFDMDecode(double[] data, int b, int e, boolean[] output) {
        Complex[] signal = DeCarrier(data, b, e - b);
        double[] phase = new double[OFDMLength / PSKLength];
        Arrays.fill(phase, Math.PI / 4);
        double MinFrequency = BaseFrequency - OffsetFrequency;
        double MaxFrequency = BaseFrequency * OFDMLength / PSKLength + OffsetFrequency;
        filter = new BandPassFilter(MinFrequency, MaxFrequency, SamplingRate);
        for (int i = 0; i < signal.length; i += SignalRealLength)
            DecodeSingleClip(signal, i + CPLength, output, i / SignalRealLength * OFDMLength, phase);
    }

    private static void DecodeSingleClip(Complex[] signal, int b1, boolean[] output, int b2, double[] phase) {
        filter.Filter(signal, b1);
        Complex[] clip = new Complex[SignalLength];
        System.arraycopy(signal, b1, clip, 0, SignalLength);
        Complex[] spectrum = fastFourierTransformer.transform(clip, TransformType.FORWARD);
        int c = OFDMLength / PSKLength;
        int[] index = new int[c];
        double[] mode = new double[spectrum.length / 2];
        for (int i = 0; i < mode.length; i++)
            mode[i] = spectrum[i].abs();
        for (int i = 0; i < c; i++) {
            index[i] = -1;
            for (int j = 0; j < mode.length; j++)
                if (index[i] == -1 || mode[j] > mode[index[i]])
                    index[i] = j;
            mode[index[i]] = -1;
        }
        Arrays.sort(index);
        int n = (int) Math.round(Math.pow(2, PSKLength));
        for (int i = 0; i < c; i++) {
            double radius = spectrum[index[i]].getArgument();
            double d = radius - phase[i];
            while (d < 0) d += Math.PI * 2;
            int value = (int) (Math.round(d * n / 2 / Math.PI) % n);
            DecimalToBitArray(output, b2 + i * PSKLength, value);
            phase[i] = radius;
        }
    }

    private static Complex[] DeCarrier(double[] data, int b, int length) {
        Complex[] result = new Complex[length];
        for (int i = 0; i < length; i++) {
            double real = data[b + i] * cos.value(2 * Math.PI * CarrierFrequency * i / SamplingRate);
            double image = -data[b + i] * sin.value(2 * Math.PI * CarrierFrequency * i / SamplingRate);
            result[i] = new Complex(real, image);
        }
        return result;
    }

    private static double[] Chirp(double beginFrequency, double endFrequency, int length) {
        double[] signal = new double[length];
        double u = (endFrequency - beginFrequency) * SamplingRate / length;
        for (int i = 0; i < length; i++) {
            double time = (double) i / SamplingRate;
            signal[i] = cos.value(Math.PI * time * time * u + 2 * Math.PI * beginFrequency * time);
        }
        return signal;
    }

    private static int ShiftPosition(double[] matchee, int offset, double[] matcher) {
        double[] correlation = Correlation(matchee, offset, matcher);
        int index = -1;
        for (int i = 0; i < correlation.length; i++)
            if (index == -1 || correlation[i] > correlation[index])
                index = i;
        return index + offset;
    }

    private static double[] Correlation(double[] a, int offset, double[] b) {
        int m = a.length, n = b.length;
        double[] result = new double[m - n - offset + 1];
        for (int i = 0; i < result.length; i++)
            for (int j = 0; j < n; j++)
                result[i] += a[i + j + offset] * b[j];
        return result;
    }
}