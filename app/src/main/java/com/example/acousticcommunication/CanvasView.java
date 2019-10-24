package com.example.acousticcommunication;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.View;

@SuppressLint("DrawAllocation")
public class CanvasView extends View {

    double[] signal;

    public CanvasView(Context context) {
        super(context);
    }

    public CanvasView(Context context, AttributeSet attributeSet) {
        super(context, attributeSet);
    }

    @Override
    public void onDraw(Canvas canvas) {
        Paint paint = new Paint();
        paint.setColor(Color.BLUE);
        paint.setStyle(Paint.Style.STROKE);
        paint.setStrokeWidth(2);
        int width = getWidth();
        int height = getHeight();
        double amplitude = height * 0.8 / 2;
        if (signal == null)
            signal = new double[width];
        for (int i = 1; i < signal.length; i++) {
            float posX1 = (float) ((i - 1) * width) / signal.length;
            float posY1 = (float) (height - signal[i - 1] * amplitude) / 2;
            float posX2 = (float) (i * width) / signal.length;
            float posY2 = (float) (height - signal[i] * amplitude) / 2;
            canvas.drawLine(posX1, posY1, posX2, posY2, paint);
        }
        paint.setColor(Color.BLACK);
        canvas.drawLine(0, height / 2, width, height / 2, paint);
        super.onDraw(canvas);
    }
}