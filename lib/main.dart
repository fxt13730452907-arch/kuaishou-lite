import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// 导入手势识别器工厂
import 'package:flutter/gestures.dart'; 
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
          // JS 脚本保持不变，用于界面黑化和模拟滚轮滑动
          _controller.runJavaScript("""
            // 1. 基础样式黑化
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important;overflow-x:hidden !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 清理页面
            function cleanPage() {
              document.body.style.setProperty('margin-left', '-15px', 'important');
              document.body.style.setProperty('width', 'calc(100vw + 15px)', 'important');
              var divs = document.querySelectorAll('div');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                if (rect.left <= 5 && rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }
              var allElements = document.querySelectorAll('*');
              for (var j = 0; j < allElements.length; j++) {
                var e = allElements[j];
                if (e.childNodes.length > 0 && e.childNodes[0].nodeType === 3) {
                  var txt = e.childNodes[0].nodeValue;
                  if (txt && (txt.indexOf('空格') > -1 || txt.indexOf('暂停') > -1 || txt.indexOf('播放') > -1)) {
                    e.style.setProperty('display', 'none', 'important');
                  }
                }
              }
            }
            setTimeout(cleanPage, 1000);
            setTimeout(cleanPage, 2500);

            // 3. 强制滑动手势 (JS模拟滚轮，作为 gestureRecognizers 的补充)
            var startY = 0;
            var isScrolling = false;
            document.addEventListener('touchstart', function(e) {
                startY = e.touches[0].clientY;
            }, {passive: false});
            document.addEventListener('touchmove', function(e) {
                if (Math.abs(e.touches[0].clientY - startY) > 10) {
                    e.preventDefault(); 
                }
            }, {passive: false});
            document.addEventListener('touchend', function(e) {
                var endY = e.changedTouches[0].clientY;
                var distance = startY - endY;
                if (Math.abs(distance) > 40 && !isScrolling) {
                    isScrolling = true;
                    var direction = distance > 0 ? 1 : -1;
                    var centerX = window.innerWidth / 2;
                    var centerY = window.innerHeight / 2;
                    var target = document.elementFromPoint(centerX, centerY) || document.body;
                    var wheelEvent = new WheelEvent('wheel', {
                        deltaY: direction * 1000,
                        bubbles: true,
                        cancelable: true,
                        clientX: centerX,
                        clientY: centerY
                    });
                    target.dispatchEvent(wheelEvent);
                    window.scrollBy({ top: direction * window.innerHeight * 0.85, behavior: 'smooth' });
                    setTimeout(function() { 
                        isScrolling = false; 
                    }, 600);
                }
            }, {passive: false});
          """);
        },
      ))
      ..loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WebViewWidget(
        controller: _controller,
        // 👇 核心修改：声明WebView优先处理垂直拖动，解决滑动失效问题
        gestureRecognizers: {
          Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
        },
      ),
    );
  }
}
