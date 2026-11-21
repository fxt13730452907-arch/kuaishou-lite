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
            // 1. 基础样式（只锁定页面，不破坏内部）
            var style = document.createElement('style');
            style.innerHTML = '''
              html, body { margin: 0 !important; padding: 0 !important; width: 100vw !important; height: 100vh !important; overflow: hidden !important; background: #000 !important; }
              header, .header, [class*="header"], [class*="nav"] { display: none !important; }
            ''';
            document.head.appendChild(style);

            // 2. 核心清理与布局修复
            function fixLayout() {
              var v = document.querySelector('video');
              if (!v) return;

              // ================= 核心：只让视频铺满并向左靠 =================
              v.style.setProperty('width', '100vw', 'important');
              v.style.setProperty('height', '100vh', 'important');
              v.style.setProperty('object-fit', 'cover', 'important');
              // 🔥 靠左显示，让画面向左移动（裁掉右边，保留左边）
              // 如果觉得不够左，可以改成 '0% center'；如果觉得太左了，改成 '20% center'
              v.style.setProperty('object-position', 'left center', 'important'); 

              // 确保视频外层容器不偏移，但千万不要改它的宽度（避免UI错位）
              var parent = v.parentElement;
              if (parent) {
                parent.style.setProperty('transform', 'none', 'important');
                parent.style.setProperty('left', '0', 'important');
              }

              // ================= 修复底部控制栏（找回全屏按钮） =================
              var allDivs = document.querySelectorAll('div');
              for (var i = 0; i < allDivs.length; i++) {
                var div = allDivs[i];
                // 寻找包含时间（如 00:05）或“倍速”的底部控制栏
                if ((div.innerText && (div.innerText.includes('倍速') || div.innerText.match(/\d{2}:\d{2}/))) && div.offsetHeight < 150) {
                  div.style.setProperty('width', '100vw', 'important');
                  div.style.setProperty('max-width', '100vw', 'important');
                  // 🔥 左对齐并强制给右侧留出 15px 的安全距离，防止全屏按钮被裁
                  div.style.setProperty('left', '0', 'important');
                  div.style.setProperty('right', 'auto', 'important');
                  div.style.setProperty('padding-left', '10px', 'important');
                  div.style.setProperty('padding-right', '20px', 'important'); // 安全边距
                  div.style.setProperty('box-sizing', 'border-box', 'important');
                }
              }

              // ================= 修复右侧按钮（点赞、评论）不被裁切 =================
              var allRightBtns = document.querySelectorAll('div[class*="right"], div[class*="sidebar"], div[class*="action"]');
              for (var j = 0; j < allRightBtns.length; j++) {
                var btn = allRightBtns[j];
                if (btn.offsetWidth < 100) { // 排除大容器，只找右侧那一小列按钮
                  btn.style.setProperty('right', '5px', 'important'); // 往左收一点点
                  btn.style.setProperty('transform', 'none', 'important');
                }
              }

              // 隐藏左侧边栏（原本的逻辑保留）
              var divs = document.querySelectorAll('div');
              for (var k = 0; k < divs.length; k++) {
                var el = divs[k];
                var rect = el.getBoundingClientRect();
                if (rect.left <= 5 && rect.width > 80 && rect.width < 350 && rect.height > window.innerHeight * 0.6) {
                  el.style.setProperty('display', 'none', 'important');
                }
              }

              // 干掉提示框
              var allElements = document.querySelectorAll('*');
              for (var m = 0; m < allElements.length; m++) {
                var e = allElements[m];
                if (e.childNodes.length > 0 && e.childNodes[0].nodeType === 3) {
                  var txt = e.childNodes[0].nodeValue;
                  if (txt && (txt.indexOf('空格') > -1 || txt.indexOf('暂停') > -1 || txt.indexOf('播放') > -1)) {
                    e.style.setProperty('display', 'none', 'important');
                  }
                }
              }
            }
            
            setTimeout(fixLayout, 1000);
            setTimeout(fixLayout, 2500);

            // 3. 自动点击全屏（如果不喜欢自动全屏，可以删掉这段）
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
