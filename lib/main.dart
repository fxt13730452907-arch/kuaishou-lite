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
            // 1. 注入基础样式：彻底黑化背景，隐藏多余元素
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important;overflow-x:hidden !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 动态处理
            setInterval(function() {
              // 背景再次强制黑化
              document.documentElement.style.setProperty('background', '#000', 'important');
              document.body.style.setProperty('background', '#000', 'important');

              // 干掉左侧边栏
              var divs = document.querySelectorAll('div');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                if (rect.left <= 5 && rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }

              // 干掉中间那个“播放 空格”的快捷键提示框
              var allElements = document.querySelectorAll('*');
              for (var j = 0; j < allElements.length; j++) {
                var e = allElements[j];
                if (e.childNodes.length > 0 && e.childNodes[0].nodeType === 3) { // 纯文本节点
                  var txt = e.childNodes[0].nodeValue;
                  if (txt && (txt.indexOf('播放') > -1 && txt.indexOf('空格') > -1)) {
                    e.style.setProperty('display', 'none', 'important');
                    if(e.parentElement) e.parentElement.style.setProperty('display', 'none', 'important');
                  }
                }
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
