package com.example.acousticcommunication;

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;

import java.io.BufferedOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Calendar;
import java.util.Date;

import static com.example.acousticcommunication.Global.Channel;
import static com.example.acousticcommunication.Global.Encoding;
import static com.example.acousticcommunication.Global.GenerateAudioFile;
import static com.example.acousticcommunication.Global.SamplingRate;
import static com.example.acousticcommunication.Global.BufferSize;
import static com.example.acousticcommunication.Global.StringToBitArray;
import static com.example.acousticcommunication.Global.BitArrayToString;
import static com.example.acousticcommunication.Global.WriteWaveFile;

@SuppressLint("SetTextI18n")
@RequiresApi(api = Build.VERSION_CODES.JELLY_BEAN)

public class MainActivity extends AppCompatActivity {
    Button StartRecordButton;
    Button StopRecordButton;
    Button PlayAudioButton;
    Button MakeAudioButton;
    TextView StatusTextView;
    EditText StorageEditText;
    EditText DataEditText;
    CanvasView PaintCanvasView;

    boolean Recording = false;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        init();

        StatusTextView.setText("STOPPED");
        StopRecordButton.setEnabled(false);
        StartRecordButton.setOnClickListener(new View.OnClickListener() {
            @SuppressLint("SetTextI18n")
            @Override
            public void onClick(View view) {
                StopRecordButton.setEnabled(true);
                StartRecordButton.setEnabled(false);
                StatusTextView.setText("RUNNING");
                Thread thread = new Thread(new Runnable() {
                    @Override
                    public void run() {
                        String path = StorageEditText.getText().toString();
                        StartRecord(path);
                        Date now = Calendar.getInstance().getTime();
                        String filepath = path + now.toString() + ".wav";
                        WriteWaveFile(filepath, path);
                    }
                });
                thread.start();
            }
        });
        StopRecordButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Recording = false;
                StopRecordButton.setEnabled(false);
                StartRecordButton.setEnabled(true);
                StatusTextView.setText("STOPPED");
            }
        });
        MakeAudioButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String text = DataEditText.getText().toString();
                ShowDialog("Confirmation", "Confirm to encode data \"" + text + "\"?");
            }
        });
        PlayAudioButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {

            }
        });
    }

    void StartRecord(String path) {
        File file = new File(path + "raw.wav");
        if (file.exists())
            file.delete();
        try {
            file.createNewFile();
        } catch (IOException e) {
            Log.e("AcousticCommunication", "failed to create file " + file.toString());
        }
        try {
            FileOutputStream outputStream = new FileOutputStream(file);
            BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(outputStream);
            DataOutputStream dataOutputStream = new DataOutputStream(bufferedOutputStream);
            AudioRecord audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, SamplingRate, Channel, Encoding, BufferSize);
            byte[] buffer = new byte[BufferSize];
            audioRecord.startRecording();
            Recording = true;
            while (Recording) {
                int length = audioRecord.read(buffer, 0, BufferSize);
                for (int i = 0; i < length; i++)
                    dataOutputStream.write(buffer[i]);
            }
            audioRecord.stop();
            dataOutputStream.close();
        } catch (Throwable t) {
            Log.e("AcousticCommunication", "record failed");
        }
    }

    private void ShowSignalOnCanvas(double[] signal) {
        PaintCanvasView.signal = signal;
        PaintCanvasView.invalidate();
    }

    private void ShowDialog(String title, String message) {
        AlertDialog.Builder dialog = new AlertDialog.Builder(this);
        dialog.setTitle(title);
        dialog.setIcon(R.mipmap.ic_launcher_round);
        dialog.setMessage(message);
        dialog.setPositiveButton("Yes"
                , new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        String text = DataEditText.getText().toString();
                        DataEditText.setText("");
                        boolean[] data = StringToBitArray(text);
                        Log.i("AcousticCommunication", BitArrayToString(data));
                        dialog.dismiss();
                        double[] signal = Modulate.Encode(data);
                        ShowSignalOnCanvas(signal);
                        String path = StorageEditText.getText().toString();
                        GenerateAudioFile(signal, path);
                    }
                });
        dialog.setNegativeButton("No"
                , new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        DataEditText.setText("");
                        dialog.dismiss();
                    }
                });
        dialog.create().show();
    }

    void init() {
        setContentView(R.layout.activity_main);
        GetPermission();

        StartRecordButton = findViewById(R.id.StartButton);
        StopRecordButton = findViewById(R.id.FinishButton);
        PlayAudioButton = findViewById(R.id.PlayButton);
        MakeAudioButton = findViewById(R.id.MakeButton);
        StatusTextView = findViewById(R.id.StatusTextView);
        StorageEditText = findViewById(R.id.StorageEditText);
        DataEditText = findViewById(R.id.DataEditText);
        PaintCanvasView = findViewById(R.id.PaintCanvasView);
    }

    private void GetPermission() {
        ActivityCompat.requestPermissions(this, new String[]{
                android.Manifest.permission.RECORD_AUDIO,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE,
                Manifest.permission.READ_EXTERNAL_STORAGE
        }, 0);
    }
}