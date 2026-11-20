import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
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
              // 1. 强制锁定网页视口，禁止网页缩放自己
              var meta = document.querySelector('meta[name="viewport"]');
              if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
              }
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';

              // 2. 隐藏左侧边栏和顶部导航
              var divs = document.querySelectorAll('div, aside, nav, header');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                if (rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6 && rect.left < 50) {
                  el.style.setProperty('display', 'none', 'important');
                }
                if (rect.height > 0 && rect.height < 80 && rect.width > window.innerWidth * 0.8) {
                   el.style.setProperty('display', 'none', 'important');
                }
              }

              // 3. 核心：把视频所在的父容器强制变成全屏固定层
              var v = document.querySelector('video');
              if (v) {
                // 向上找两层父节点，直接铺满屏幕
                var p = v.parentElement ? v.parentElement.parentElement : null;
                if (p) {
                  p.style.setProperty('position', 'fixed', 'important');
                  p.style.setProperty('top', '0', 'important');
                  p.style.setProperty('left', '0', 'important');
                  p.style.setProperty('width', '100vw', 'important');
                  p.style.setProperty('height', '100vh', 'important');
                  p.style.setProperty('z-index', '9999', 'important');
                  p.style.setProperty('margin', '0', 'important');
                  p.style.setProperty('padding', '0', 'important');
                  p.style.setProperty('background', '#000', 'important');
                }
                // 视频本身铺满
                v.style.setProperty('width', '100%', 'important');
                v.style.setProperty('height', '100%', 'important');
                v.style.setProperty('object-fit', 'contain', 'important'); // 用 contain 防止画面被切掉
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
