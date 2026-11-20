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
            // 1. 隐藏多余元素并黑化背景
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important; overflow-x:hidden !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 清理页面
            function cleanPage() {
              // 干掉左侧边栏
              var divs = document.querySelectorAll('div');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                if (rect.left <= 5 && rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }

              // 干掉提示框
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

              // 3. 核心：强制视频铺满放大
              var v = document.querySelector('video');
              if (v) {
                // 强制视频容器铺满屏幕
                v.style.setProperty('width', '100vw', 'important');
                v.style.setProperty('height', '100vh', 'important');
                // 自动缩放裁剪，不留黑边
                v.style.setProperty('object-fit', 'cover', 'important'); 
                
                // 如果视频父容器有宽度限制，一并解除
                if (v.parentElement) {
                    v.parentElement.style.setProperty('width', '100vw', 'important');
                    v.parentElement.style.setProperty('max-width', '100vw', 'important');
                }
              }
            }
            
            // 延迟执行，确保视频已经加载
            setTimeout(cleanPage, 1000);
            setTimeout(cleanPage, 2500);

            // 4. 滑动引擎
            var startY = 0;
            document.addEventListener('touchstart', function(e) {
                startY = e.touches[0].clientY;
            }, {passive: true});

            document.addEventListener('touchend', function(e) {
                var endY = e.changedTouches[0].clientY;
                var distance = startY - endY;
                if (Math.abs(distance) > 40) {
                    var direction = distance > 0 ? 1 : -1;
                    var centerX = window.innerWidth / 2;
                    var centerY = window.innerHeight / 2;
                    var target = document.elementFromPoint(centerX, centerY) || document.body;
                    var wheelEvent = new WheelEvent('wheel', {
                        deltaY: direction * 1000, bubbles: true, cancelable: true, clientX: centerX, clientY: centerY
                    });
                    target.dispatchEvent(wheelEvent);
                }
            }, {passive: true});
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
