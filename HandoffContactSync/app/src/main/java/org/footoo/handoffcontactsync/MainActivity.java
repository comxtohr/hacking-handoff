package org.footoo.handoffcontactsync;

import android.app.Activity;
import android.content.res.AssetFileDescriptor;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.content.Intent;
import android.provider.ContactsContract;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.google.zxing.integration.android.IntentIntegrator;
import com.google.zxing.integration.android.IntentResult;

import java.io.FileInputStream;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;

public class MainActivity extends Activity implements OnClickListener {

    private Button btnScan;
    private TextView txvResult;
    private DatagramSocket socket;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        btnScan = (Button)findViewById(R.id.button_scan);
        txvResult = (TextView)findViewById(R.id.textview_result);

        btnScan.setOnClickListener(this);
    }

    public void onClick(View v){
        if(v.getId()==R.id.button_scan){
            IntentIntegrator scanIntegrator = new IntentIntegrator(this);
            scanIntegrator.initiateScan();
        }
    }

    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        IntentResult scanningResult = IntentIntegrator.parseActivityResult(requestCode, resultCode, intent);
        if (scanningResult != null) {
            String scanContent = scanningResult.getContents();
            txvResult.setText(scanContent);
            new Thread(new udpThread()).start();
        }
        else{
            Toast toast = Toast.makeText(getApplicationContext(),"No scan data received!", Toast.LENGTH_SHORT);
            toast.show();
        }
    }

    class udpThread implements Runnable {
        @Override
        public void run() {
            Cursor phones = getContentResolver().query(ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null, null, null, null);
            phones.moveToFirst();
            for (int i = 0; i < phones.getCount(); i++) {
                String lookupKey = phones.getString(phones.getColumnIndex(ContactsContract.Contacts.LOOKUP_KEY));
                Uri uri = Uri.withAppendedPath(ContactsContract.Contacts.CONTENT_VCARD_URI,lookupKey);
                AssetFileDescriptor fd;
                try {
                    fd = getContentResolver().openAssetFileDescriptor(uri, "r");
                    FileInputStream fis = fd.createInputStream();
                    byte[] buf = new byte[(int) fd.getDeclaredLength()];
                    fis.read(buf);
                    String VCard = new String(buf);

                    phones.moveToNext();
                    Log.d("Vcard", VCard);

                    socket = new DatagramSocket();
                    String sendStr = VCard;
                    byte[] sendBuf;
                    sendBuf = sendStr.getBytes();
                    String addr = txvResult.getText().toString();
                    DatagramPacket sendPacket = new DatagramPacket(sendBuf, sendBuf.length, InetAddress.getByName(addr), 9999);
                    socket.send(sendPacket);
                    socket.close();

                } catch (Exception e1) {
                    // TODO Auto-generated catch block
                    e1.printStackTrace();
                }
            }
        }
    }
}
