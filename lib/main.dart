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
          // 注入几何物理清理大法 + 强制全屏
          _controller.runJavaScript("""
            setTimeout(function(){
              // 1. 把视频所在的父级容器，一层层往上扒，全部强制拉满屏幕
              var v = document.querySelector('video');
              if (v) {
                var p = v;
                for (var i = 0; i < 6; i++) {
                  if (p) {
                    p.style.setProperty('width', '100vw', 'important');
                    p.style.setProperty('height', '100vh', 'important');
                    p.style.setProperty('max-width', '100vw', 'important');
                    p.style.setProperty('max-height', '100vh', 'important');
                    p.style.setProperty('margin', '0', 'important');
                    p.style.setProperty('padding', '0', 'important');
                    p.style.setProperty('left', '0', 'important');
                    p.style.setProperty('right', '0', 'important');
                    p.style.setProperty('top', '0', 'important');
                    p = p.parentNode;
                  }
                }
              }
              
              // 2. 暴力扫描并隐藏左侧边栏
              var els = document.querySelectorAll('div, aside, nav, header');
              for (var j = 0; j < els.length; j++) {
                var el = els[j];
                var rect = el.getBoundingClientRect();
                // 只要又高又窄，且靠左，直接干掉
                if (rect.width > 50 && rect.width < 350 && rect.height > window.innerHeight * 0.7 && rect.left < 30) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }
              
              // 3. 全局变黑
              document.body.style.setProperty('background', '#000', 'important');
            }, 1500);
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
