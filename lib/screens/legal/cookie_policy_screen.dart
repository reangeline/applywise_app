import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CookiePolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cookie Policy'),
      ),
      body: WebView(
        initialUrl: 'https://hirefy.careers/cookies',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}