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
      // 保持你原本的 Windows UA
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          _controller.runJavaScript("""
            // 1. 基础样式
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important; overflow-x:hidden !important; margin:0 !important; padding:0 !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 清理与强制居中铺满
            function cleanPage() {
              document.body.style.setProperty('margin-left', '0', 'important');
              document.body.style.setProperty('width', '100vw', 'important');

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

              // 3. 核心：强行铺满 + 画面左移
              var v = document.querySelector('video');
              if (v) {
                var p = v;
                for (var k = 0; k < 4; k++) {
                  if (p) {
                    p.style.setProperty('width', '100vw', 'important');
                    p.style.setProperty('max-width', '100vw', 'important');
                    p.style.setProperty('margin', '0', 'important'); // 取消 auto 防止容器偏移
                    p.style.setProperty('padding', '0', 'important');
                    p.style.setProperty('left', '0', 'important');
                    p.style.setProperty('transform', 'none', 'important');
                    p = p.parentElement;
                  }
                }
                v.style.setProperty('width', '100vw', 'important');
                v.style.setProperty('height', '100vh', 'important');
                v.style.setProperty('object-fit', 'cover', 'important');
                
                // 🔥 核心修改：让画面向左移动！
                // 'right center' 表示右侧对齐，相当于镜头向左看，画面整体左移。
                // 如果你觉得移得不够，可以试试 '10% center' 或者 '20% center'
                v.style.setProperty('object-position', 'right center', 'important'); 
              }

              // 4. 保护底部全屏按钮不被挤出屏幕
              var bottomBarDivs = document.querySelectorAll('div');
              for (var m = 0; m < bottomBarDivs.length; m++) {
                var div = bottomBarDivs[m];
                if (div.innerText && (div.innerText.includes('倍速') || div.innerText.match(/\d{2}:\d{2}/))) {
                  if (div.offsetHeight < 150) {
                    div.style.setProperty('width', '100vw', 'important');
                    div.style.setProperty('box-sizing', 'border-box', 'important');
                    // 强行给右侧留出 20px 的救命内边距
                    div.style.setProperty('padding-right', '20px', 'important'); 
                  }
                }
              }
            }
            
            setTimeout(cleanPage, 1000);
            setTimeout(cleanPage, 2500);

            // 5. 核心新增：安全延迟后，自动帮你点一次“全屏”按钮
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
