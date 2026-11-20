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
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // 物理位移：把整个网页向左推，挤出侧边栏
          _controller.runJavaScript("""
            setInterval(function() {
              // 1. 隐藏左侧边栏
              var divs = document.querySelectorAll('div, aside, nav');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                if (rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6 && rect.left < 50) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }
              
              // 2. 把整个网页往左硬拉 200px，强行盖住黑边
              document.body.style.setProperty('margin-left', '-220px', 'important');
              document.body.style.setProperty('width', 'calc(100vw + 220px)', 'important');
              document.body.style.setProperty('overflow-x', 'hidden', 'important');
              document.body.style.setProperty('background', '#000', 'important');

              // 3. 让视频稍微放大一点点，填满右侧空间
              var v = document.querySelector('video');
              if (v) {
                v.style.setProperty('width', '100vw', 'important');
                v.style.setProperty('height', '100vh', 'important');
                v.style.setProperty('object-fit', 'cover', 'important');
              }
            }, 1000);
          """);
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
