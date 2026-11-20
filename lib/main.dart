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
            // 1. 暴力注入全局 CSS
            var style = document.createElement('style');
            style.innerHTML = 'html, body { background: #000 !important; overflow-x: hidden !important; margin: 0 !important; padding: 0 !important; } * { max-width: 100vw !important; }';
            document.head.appendChild(style);

            function cleanPage() {
              // 2. 暴力干掉所有左侧的侧边栏容器
              var divs = document.querySelectorAll('div, aside, nav, header');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                // 只要它靠左 (left<50)，且占了一定宽度(>50)，且比较高(>屏幕50%)，直接干掉
                if (rect.left < 50 && rect.width > 50 && rect.height > window.innerHeight * 0.5) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }

              // 3. 暴力释放中心播放器容器
              var v = document.querySelector('video');
              if (v) {
                var p = v;
                // 向上找 7 层父级，彻底清除边距，全部拉满 100vw
                for (var k = 0; k < 7; k++) {
                  if (p) {
                    p.style.setProperty('width', '100vw', 'important');
                    p.style.setProperty('max-width', '100vw', 'important');
                    p.style.setProperty('margin', '0', 'important');
                    p.style.setProperty('padding', '0', 'important');
                    p.style.setProperty('left', '0', 'important');
                    p.style.setProperty('position', 'relative', 'important');
                    p = p.parentElement;
                  }
                }
                // 视频本身强行裁剪铺满
                v.style.setProperty('width', '100vw', 'important');
                v.style.setProperty('height', '100vh', 'important');
                v.style.setProperty('object-fit', 'cover', 'important');
              }
              
              // 4. 干掉中间的快捷键提示
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
            setTimeout(cleanPage, 4000);

            // 5. 滑动引擎
            var startY = 0;
            document.addEventListener('touchstart', function(e) { startY = e.touches[0].clientY; }, {passive: true});
            document.addEventListener('touchend', function(e) {
                var endY = e.changedTouches[0].clientY;
                var distance = startY - endY;
                if (Math.abs(distance) > 40) {
                    var direction = distance > 0 ? 1 : -1;
                    var centerX = window.innerWidth / 2;
                    var centerY = window.innerHeight / 2;
                    var target = document.elementFromPoint(centerX, centerY) || document.body;
                    var wheelEvent = new WheelEvent('wheel', { deltaY: direction * 1000, bubbles: true, cancelable: true, clientX: centerX, clientY: centerY });
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
