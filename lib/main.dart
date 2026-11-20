import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 强制开启全屏沉浸式，让内容延伸到状态栏和导航栏下方
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // 顶部时间电量图标变白
    systemNavigationBarIconBrightness: Brightness.light, // 底部导航图标变白
  ));
  
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

              // 2. 隐藏顶部导航栏（搜索框那一排）
              var headers = document.querySelectorAll('header, .header, [class*="header"]');
              for (var j = 0; j < headers.length; j++) {
                  headers[j].style.setProperty('display', 'none', 'important');
              }

              // 3. 把整个网页往左硬拉 220px，掩盖黑边
              document.body.style.setProperty('margin-left', '-220px', 'important');
              document.body.style.setProperty('width', 'calc(100vw + 220px)', 'important');
              document.body.style.setProperty('overflow-x', 'hidden', 'important');
              document.body.style.setProperty('background', '#000', 'important');

              // 4. 确保视频填满屏幕
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
      // 去掉了 SafeArea，直接用 WebViewWidget 铺满整个 Scaffold
      body: WebViewWidget(controller: _controller),
    );
  }
}
