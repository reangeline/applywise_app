import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Service'),
      ),
      body: WebView(
        initialUrl: 'https://hirefy.careers/terms',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}