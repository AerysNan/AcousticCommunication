package com.example.acousticcommunication;

import org.apache.commons.math3.analysis.function.Cos;
import org.apache.commons.math3.analysis.function.Sin;
import org.apache.commons.math3.complex.Complex;

import static com.example.acousticcommunication.Global.*;

class Modulate {

    private static Cos cos = new Cos();
    private static Sin sin = new Sin();

    static double[] Encode(boolean[] data) {
        int length = data.length * SignalRealLength / OFDMLength;
        Complex[] content = new Complex[length + HeadChirpLength + TailChirpLength];
        for (int i = 0; i < content.length; i++)
            content[i] = new Complex(0);
        double[] phase = new double[OFDMLength / PSKLength];
        for (int i = 0; i < phase.length; i++)
            phase[i] = Math.PI / 4;
        OFDMEncode(data, content, HeadChirpLength, phase);
        double[] signal = Carrier(content, HeadChirpLength, length);
        Normalize(signal, HeadChirpLength, length);
        Chirp(HeadChirpBeginFrequency, HeadChirpEndFrequency, signal, 0, HeadChirpLength);
        Chirp(TailChirpBeginFrequency, TailChirpEndFrequency, signal, length + HeadChirpLength, TailChirpLength);
        return signal;
    }

    private static void OFDMEncode(boolean[] data, Complex[] output, int b, double[] prev) {
        for (int i = 0; i < data.length; i += OFDMLength) {
            EncodeSingleClip(data, i, output, b + i * SignalLength / OFDMLength + CPLength, prev);
            CreateCyclicPrefix(output, b + i * SignalLength / OFDMLength);
            Carrier(output, b + i * SignalLength / OFDMLength, SignalRealLength);
        }
    }

    private static void EncodeSingleClip(boolean[] data, int b1, Complex[] output, int b2, double[] prev) {
        for (int j = 0; j < OFDMLength; j += PSKLength)
            PSKEncode((j / PSKLength + 1) * BaseFrequency, data, b1 + j, output, b2, prev, j / PSKLength);
    }

    private static void PSKEncode(int frequency, boolean[] data, int b1, Complex[] output, int b2, double[] prev, int index) {
        double n = Math.pow(2, PSKLength);
        int value = BitArrayToDecimal(data, b1);
        for (int i = 0; i < SignalLength; i++) {
            double phase = 2 * value / n * Math.PI + prev[index];
            Complex c = new Complex(0, 2 * Math.PI * frequency * i / SamplingRate + phase);
            output[i + b2] = output[i + b2].add(c.exp());
        }
    }

    private static void CreateCyclicPrefix(Complex[] output, int b) {
        System.arraycopy(output, b + SignalLength, output, b, CPLength);
    }

    private static void Normalize(double[] data, int b, int length) {
        double max = -1;
        for (int i = b; i < b + length; i++)
            max = Math.max(max, data[i]);
        for (int i = b; i < b + length; i++)
            data[i] /= max;
    }

    private static double[] Carrier(Complex[] output, int b, int length) {
        double[] result = new double[output.length];
        for (int i = b; i < b + length; i++)
            result[i] = output[i].getReal() * cos.value(2 * Math.PI * CarrierFrequency * (i - b) / SamplingRate)
                    - output[i].getImaginary() * sin.value(2 * Math.PI * CarrierFrequency * (i - b) / SamplingRate);
        return result;
    }

    private static void Chirp(double beginFrequency, double endFrequency, double[] output, int b, int length) {
        double u = (endFrequency - beginFrequency) * SamplingRate / length;
        for (int i = 0; i < length; i++) {
            double time = (double) i / SamplingRate;
            output[b + i] = cos.value(Math.PI * time * time * u + 2 * Math.PI * beginFrequency * time);
        }
    }
}