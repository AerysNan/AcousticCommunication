package com.example.acousticcommunication;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.util.Log;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

class Global {
    static final int SamplingRate = 44100;
    static final int Channel = AudioFormat.CHANNEL_IN_MONO;
    static final int Encoding = AudioFormat.ENCODING_PCM_16BIT;
    static final int BufferSize = AudioRecord.getMinBufferSize(SamplingRate, Channel, Encoding);

    static final int SignalLength = 882;
    static final int BaseFrequency = 100;
    static final int CarrierFrequency = 1000;
    static final int PSKLength = 2;
    static final int OFDMLength = 8;
    static final int CPLength = 32;
    static final int HeadChirpLength = 882;
    static final int TailChirpLength = 441;
    static final int HeadChirpBeginFrequency = 200;
    static final int HeadChirpEndFrequency = 600;
    static final int TailChirpBeginFrequency = 600;
    static final int TailChirpEndFrequency = 1000;
    static final int SignalRealLength = CPLength + SignalLength;

    static int BitArrayToDecimal(boolean[] data, int b) {
        int value = 0;
        for (int i = b + PSKLength - 1; i >= b; i--)
            value = value * 2 + (data[i] ? 1 : 0);
        return value;
    }

    static boolean[] StringToBitArray(String s) {
        int n = s.length();
        boolean[] result = new boolean[8 * n];
        for (int i = 0; i < n; i++) {
            int value = (int) s.charAt(i);
            for (int j = 0; j < 8; j++) {
                result[i * 8 + j] = value % 2 == 1;
                value /= 2;
            }
        }
        return result;
    }

    static String BitArrayToString(boolean[] value) {
        StringBuilder stringBuilder = new StringBuilder();
        for (boolean b : value)
            stringBuilder.append(b ? 1 : 0);
        return stringBuilder.toString();
    }

    static void GenerateAudioFile(double[] data, String name) {
        File file = new File(name + "output.wav");
        if (file.exists())
            file.delete();
        try {
            file.createNewFile();
        } catch (IOException e) {
            Log.e("AcousticCommunication", "failed to create file " + file.toString());
        }
        int channels = 1;
        long byteRate = 16 * SamplingRate * channels / 8;
        byte[] buffer = new byte[BufferSize];
        byte[] content = new byte[2 * data.length];
        ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(content);
        for (int i = 0; i < data.length; i++) {
            short value = (short) (data[i] * Short.MAX_VALUE);
            content[2 * i] = (byte) (value & 0xff);
            content[2 * i + 1] = (byte) (value >> 8);
        }
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(file);
            long audioLength = content.length;
            long dataLength = audioLength + 36;
            WriteWaveFileHeader(fileOutputStream, audioLength, dataLength, (long) SamplingRate, channels, byteRate);
            while (byteArrayInputStream.read(buffer) != -1)
                fileOutputStream.write(buffer);
            byteArrayInputStream.close();
            fileOutputStream.close();
        } catch (FileNotFoundException e) {
            Log.e("AcousticCommunication", "output file not found");
        } catch (IOException e) {
            Log.e("AcousticCommunication", "write wave file failed");
        }
    }

    static void WriteWaveFile(String outFileName, String path) {
        int channels = 1;
        long byteRate = 16 * SamplingRate * channels / 8;
        byte[] data = new byte[BufferSize];
        try {
            FileInputStream fileInputStream = new FileInputStream(path + "raw.wav");
            FileOutputStream fileOutputStream = new FileOutputStream(outFileName);
            long audioLength = fileInputStream.getChannel().size();
            long dataLength = audioLength + 36;
            WriteWaveFileHeader(fileOutputStream, audioLength, dataLength, (long) SamplingRate, channels, byteRate);
            while (fileInputStream.read(data) != -1)
                fileOutputStream.write(data);
            fileInputStream.close();
            fileOutputStream.close();
        } catch (FileNotFoundException e) {
            Log.e("AcousticCommunication", "audio file not found");
        } catch (IOException e) {
            Log.e("AcousticCommunication", "write wave file failed");
        }
    }

    private static void WriteWaveFileHeader(FileOutputStream fileOutputStream, long audioLength,
                                            long dataLength, long sampleRate, int channels, long byteRate)
            throws IOException {
        byte[] header = new byte[44];
        header[0] = 'R';
        header[1] = 'I';
        header[2] = 'F';
        header[3] = 'F';
        header[4] = (byte) (dataLength & 0xff);
        header[5] = (byte) ((dataLength >> 8) & 0xff);
        header[6] = (byte) ((dataLength >> 16) & 0xff);
        header[7] = (byte) ((dataLength >> 24) & 0xff);
        header[8] = 'W';
        header[9] = 'A';
        header[10] = 'V';
        header[11] = 'E';
        header[12] = 'f';
        header[13] = 'm';
        header[14] = 't';
        header[15] = ' ';
        header[16] = 16;
        header[17] = 0;
        header[18] = 0;
        header[19] = 0;
        header[20] = 1;
        header[21] = 0;
        header[22] = (byte) channels;
        header[23] = 0;
        header[24] = (byte) (sampleRate & 0xff);
        header[25] = (byte) ((sampleRate >> 8) & 0xff);
        header[26] = (byte) ((sampleRate >> 16) & 0xff);
        header[27] = (byte) ((sampleRate >> 24) & 0xff);
        header[28] = (byte) (byteRate & 0xff);
        header[29] = (byte) ((byteRate >> 8) & 0xff);
        header[30] = (byte) ((byteRate >> 16) & 0xff);
        header[31] = (byte) ((byteRate >> 24) & 0xff);
        header[32] = (byte) (2 * 16 / 8);
        header[33] = 0;
        header[34] = 16;
        header[35] = 0;
        header[36] = 'd';
        header[37] = 'a';
        header[38] = 't';
        header[39] = 'a';
        header[40] = (byte) (audioLength & 0xff);
        header[41] = (byte) ((audioLength >> 8) & 0xff);
        header[42] = (byte) ((audioLength >> 16) & 0xff);
        header[43] = (byte) ((audioLength >> 24) & 0xff);
        fileOutputStream.write(header, 0, 44);
    }
}