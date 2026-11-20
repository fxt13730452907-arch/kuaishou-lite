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
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          _controller.runJavaScript("""
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important;overflow-x:hidden !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            function cleanPage() {
              document.documentElement.style.setProperty('background', '#000', 'important');
              document.body.style.setProperty('background', '#000', 'important');

              // 1. 干掉左侧边栏
              var divs = document.querySelectorAll('div');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                if (rect.left <= 5 && rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }

              // 2. 干掉中间提示框
              var allElements = document.querySelectorAll('*');
              for (var j = 0; j < allElements.length; j++) {
                var e = allElements[j];
                if (e.childNodes.length > 0 && e.childNodes[0].nodeType === 3) {
                  var txt = e.childNodes[0].nodeValue;
                  if (txt && (txt.indexOf('播放') > -1 && txt.indexOf('空格') > -1)) {
                    e.style.setProperty('display', 'none', 'important');
                    if(e.parentElement) e.parentElement.style.setProperty('display', 'none', 'important');
                  }
                }
              }

              // 3. 核心修复：消除左侧黑边
              // 把视频以及它的 5 层父节点全部强制设置 margin/padding 为 0，并拉宽
              var v = document.querySelector('video');
              if (v) {
                var node = v;
                for (var k = 0; k < 5; k++) {
                  if (node) {
                    node.style.setProperty('margin-left', '0', 'important');
                    node.style.setProperty('padding-left', '0', 'important');
                    node.style.setProperty('max-width', 'none', 'important');
                    node.style.setProperty('width', '100vw', 'important');
                    node.style.setProperty('left', '0', 'important');
                    node = node.parentElement;
                  }
                }
              }
              
              // 4. 兜底：整体网页向左强行偏移 -15px，并拉宽，吃掉最后的边缘缝隙
              document.body.style.setProperty('margin-left', '-15px', 'important');
              document.body.style.setProperty('width', 'calc(100vw + 15px)', 'important');
            }

            setTimeout(cleanPage, 500);
            setTimeout(cleanPage, 1500);
            setTimeout(cleanPage, 3000);
          """);
        },
        onWebResourceError: (WebResourceError error) {
          if (_retryCount < 3) {
            _retryCount++;
            Future.delayed(const Duration(seconds: 2), () {
              _controller.reload();
            });
          }
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
