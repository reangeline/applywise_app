import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RefundPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Refund Policy'),
      ),
      body: WebView(
        initialUrl: 'https://hirefy.careers/refund',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}