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
      // 保持你的 Windows UA
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          _controller.runJavaScript("""
            // 1. 基础样式重置
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important; overflow:hidden !important; margin:0 !important; padding:0 !important; width:100vw !important;} header,.header,[class*="header"],[class*="nav"]{display:none !important;} aside,.sidebar{display:none !important;}';
            document.head.appendChild(style);

            // 2. 清理与布局修复
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

              // 3. 核心：干掉左侧黑边，让视频铺满
              var v = document.querySelector('video');
              if (v) {
                var p = v;
                // 向上遍历 6 层父节点，暴力清除所有偏移量
                for (var k = 0; k < 6; k++) {
                  if (p) {
                    p.style.setProperty('width', '100vw', 'important');
                    p.style.setProperty('max-width', '100vw', 'important');
                    p.style.setProperty('margin', '0', 'important');
                    p.style.setProperty('padding', '0', 'important');
                    p.style.setProperty('left', '0', 'important');
                    p.style.setProperty('right', '0', 'important');
                    p.style.setProperty('transform', 'none', 'important');
                    p = p.parentElement;
                  }
                }
                v.style.setProperty('width', '100vw', 'important');
                v.style.setProperty('height', '100vh', 'important');
                v.style.setProperty('object-fit', 'cover', 'important');
                
                // 🔥 强行让画面向右对齐，以抵消左侧的留白（视觉上画面整体左移）
                v.style.setProperty('object-position', 'right center', 'important'); 
              }

              // 4. 找回右下角全屏按钮
              // 找到底部控制栏，强制往左拉回屏幕内
              var allDivs = document.querySelectorAll('div');
              for (var m = 0; m < allDivs.length; m++) {
                var div = allDivs[m];
                var txt = div.innerText || '';
                // 识别底部控制栏（包含倍速或时间）
                if ((txt.includes('倍速') || txt.match(/\d{2}:\d{2}/)) && div.offsetHeight < 150) {
                  div.style.setProperty('width', '100vw', 'important');
                  div.style.setProperty('box-sizing', 'border-box', 'important');
                  // 去掉你之前说不要的安全距离，直接把右边距设死
                  div.style.setProperty('padding-right', '0', 'important');
                  // 🔥 核心：把整个控制栏往左强行拉扯，把全屏按钮拉出来
                  div.style.setProperty('right', '10px', 'important'); 
                }
              }

              // 🔥 暴力抢救全屏按钮（即使被隐藏了也给它弄出来）
              var els = document.querySelectorAll('div, button, span, svg, path');
              for (var n = 0; n < els.length; n++) {
                var el = els[n];
                var title = el.getAttribute('title') || el.getAttribute('aria-label') || '';
                if (title.indexOf('全屏') > -1 || title.indexOf('fullscreen') > -1) {
                  el.style.setProperty('display', 'block', 'important');
                  el.style.setProperty('visibility', 'visible', 'important');
                  el.style.setProperty('opacity', '1', 'important');
                }
              }
            }
            
            setTimeout(cleanPage, 1000);
            setTimeout(cleanPage, 2500);

            // 5. 自动点击全屏
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
