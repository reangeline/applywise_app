import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
      ),
      body: WebView(
        initialUrl: 'https://hirefy.careers/privacy',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}