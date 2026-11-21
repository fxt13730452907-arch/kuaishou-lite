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
            // 1. 基础样式
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important; overflow:hidden !important; margin:0 !important; padding:0 !important; width:100vw !important; height:100vh !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 核心清理与布局修复
            function fixLayout() {
              var v = document.querySelector('video');
              if (!v) return;

              // 强制清除 video 外层容器的偏移
              var parent = v.parentElement;
              var depth = 0;
              while (parent && depth < 4) {
                parent.style.setProperty('margin', '0', 'important');
                parent.style.setProperty('padding', '0', 'important');
                parent.style.setProperty('width', '100vw', 'important');
                parent.style.setProperty('max-width', '100vw', 'important');
                parent.style.setProperty('left', '0', 'important');
                parent.style.setProperty('transform', 'none', 'important'); // 清除之前的位移
                parent = parent.parentElement;
                depth++;
              }

              // 3. 强制视频铺满屏幕，并设置画面向左偏移
              v.style.setProperty('width', '100vw', 'important');
              v.style.setProperty('height', '100vh', 'important');
              v.style.setProperty('object-fit', 'cover', 'important');
              // 🔥 关键点1：使用 object-position 让画面向左靠，不影响其他按钮
              // 如果觉得靠左不够，可以把 'left center' 改成 '30% center' 甚至 '0% center'
              v.style.setProperty('object-position', 'left center', 'important'); 
              
              // 4. 修复底部控制栏，把“全屏”按钮拉回来
              var allDivs = document.querySelectorAll('div');
              for (var i = 0; i < allDivs.length; i++) {
                var div = allDivs[i];
                // 寻找包含“倍速”或“全屏”字样的底部控制栏
                if (div.innerText && (div.innerText.includes('倍速') || div.innerText.includes('全屏'))) {
                  div.style.setProperty('width', '100vw', 'important');
                  div.style.setProperty('max-width', '100vw', 'important');
                  div.style.setProperty('left', '0', 'important');
                  div.style.setProperty('right', '0', 'important');
                  div.style.setProperty('box-sizing', 'border-box', 'important');
                  // 🔥 关键点2：强制给右侧留出 15px 的内边距，防止全屏按钮被屏幕边缘切掉
                  div.style.setProperty('padding-right', '15px', 'important');
                }
              }
            }
            
            setTimeout(fixLayout, 1000);
            setTimeout(fixLayout, 2500);

            // 5. 安全延迟后，自动帮你点一次“全屏”按钮 (如果不想要自动全屏，可以删掉这段)
            window._hasAutoClicked = false;
            function clickFullscreen() {
              if (window._hasAutoClicked) return;
              var els = document.querySelectorAll('div, button, span, svg, path');
              for (var i = 0; i < els.length; i++) {
                var el = els[i];
                var title = el.getAttribute('title') || el.getAttribute('aria-label') || '';
                if (title.indexOf('全屏') > -1 || title.indexOf('fullscreen') > -1) {
                  el.click();
                  window._hasAutoClicked = true;
                  return;
                }
              }
            }
            setTimeout(clickFullscreen, 2500);

            // 6. 滑动引擎
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
