package com.example.alarm_app


import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity(){
    override fun onCreate(savedInstanceState: Bundle?){
        super.on Create(savedInstanceState)
        if(Build.VERSION.SDK.INT >=Build.VERSION_CODES.O_MR1){
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        else{
            @Suppress("DEPRECIATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        @Suppress("DEPRECIATION")
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }
}

