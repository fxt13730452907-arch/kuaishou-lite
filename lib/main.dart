import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 去掉了那个可能导致编译崩溃的 setMediaPlaybackRequiresUserGesture
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // 极简一行 JS，不包含任何可能让编译器崩溃的字符
          String safeJs = "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;overflow-x:hidden!important;}aside,.sidebar,header,.header{display:none!important}video{width:100vw!important;height:100vh!important;object-fit:cover!important;}';document.head.appendChild(s);setTimeout(function(){var e=new KeyboardEvent('keydown',{key:'h',keyCode:72,bubbles:true});document.dispatchEvent(e);},2500);";
          
          _controller.runJavaScript(safeJs);
        },
      ))
      ..loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WebViewWidget(controller: _controller),
    );
  }
}
