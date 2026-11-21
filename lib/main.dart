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
            style.innerHTML = 'html,body{background:#000 !important; overflow-x:hidden !important; margin:0 !important; padding:0 !important; width:100% !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 清理与强制居中铺满
            function cleanPage() {
              // 强制重置 html 和 body 的宽度与溢出，防止页面被撑开偏移
              document.documentElement.style.setProperty('width', '100%', 'important');
              document.documentElement.style.setProperty('overflow-x', 'hidden', 'important');
              document.body.style.setProperty('margin', '0', 'important');
              document.body.style.setProperty('padding', '0', 'important');
              document.body.style.setProperty('width', '100%', 'important');
              document.body.style.setProperty('overflow-x', 'hidden', 'important');

              // 干掉左侧边栏 并 重置导致右移的边距
              var divs = document.querySelectorAll('div');
              for (var i = 0; i < divs.length; i++) {
                var el = divs[i];
                var rect = el.getBoundingClientRect();
                // 隐藏左侧边栏
                if (rect.left <= 5 && rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6) {
                  el.style.setProperty('display', 'none', 'important');
                }
                // 重置可能导致页面右移的 margin 和 padding
                var computedStyle = window.getComputedStyle(el);
                if (parseInt(computedStyle.marginLeft) > 0 || parseInt(computedStyle.paddingLeft) > 0) {
                  if (el.offsetWidth > window.innerWidth * 0.5) {
                    el.style.setProperty('margin-left', '0', 'important');
                    el.style.setProperty('padding-left', '0', 'important');
                    el.style.setProperty('left', '0', 'important');
                  }
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

              // 3. 核心：强行居中铺满并【向左偏移】
              var v = document.querySelector('video');
              if (v) {
                var p = v;
                for (var k = 0; k < 4; k++) {
                  if (p) {
                    p.style.setProperty('width', '100%', 'important');
                    p.style.setProperty('max-width', '100%', 'important');
                    p.style.setProperty('margin', '0', 'important');
                    p.style.setProperty('padding', '0', 'important');
                    p.style.setProperty('left', '0', 'important');
                    p.style.setProperty('transform', 'none', 'important');
                    p = p.parentElement;
                  }
                }
                v.style.setProperty('width', '100%', 'important');
                v.style.setProperty('height', '100vh', 'important');
                v.style.setProperty('object-fit', 'cover', 'important');
                
                // 🔥 核心修改：让画面向左移动
                // 调整这里的像素值（例如 -20px, -50px）或者百分比（-5vw）来实现左移效果
                v.style.setProperty('transform', 'translateX(-20px)', 'important'); 
              }
            }
            
            setTimeout(cleanPage, 1000);
            setTimeout(cleanPage, 2500);

            // 4. 核心新增：安全延迟后，自动帮你点一次“全屏”按钮
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

            // 5. 滑动引擎
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
