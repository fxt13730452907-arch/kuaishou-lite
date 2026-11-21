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
            // 1. 基础样式
            var style = document.createElement('style');
            style.innerHTML = 'html,body{background:#000 !important; overflow:hidden !important; margin:0 !important; padding:0 !important; width:100vw !important; height:100vh !important;}';
            document.head.appendChild(style);

            // 2. 核心清理逻辑
            function fixLayout() {
              // ================= 第一步：暴力碾碎左侧黑边 =================
              var v = document.querySelector('video');
              if (v) {
                var p = v;
                // 向上找 8 层父容器，全部强制宽度 100vw，边距归零，定位重置
                for (var k = 0; k < 8; k++) {
                  if (p) {
                    p.style.setProperty('width', '100vw', 'important');
                    p.style.setProperty('max-width', '100vw', 'important');
                    p.style.setProperty('height', '100vh', 'important');
                    p.style.setProperty('margin', '0', 'important');
                    p.style.setProperty('padding', '0', 'important');
                    p.style.setProperty('left', '0', 'important');
                    p.style.setProperty('top', '0', 'important');
                    p.style.setProperty('right', '0', 'important');
                    p.style.setProperty('bottom', '0', 'important');
                    p.style.setProperty('transform', 'none', 'important');
                    p.style.setProperty('border-radius', '0', 'important'); // 去圆角
                    p = p.parentElement;
                  }
                }
                
                // 视频本体铺满，并且画面左对齐
                v.style.setProperty('width', '100vw', 'important');
                v.style.setProperty('height', '100vh', 'important');
                v.style.setProperty('object-fit', 'cover', 'important');
                v.style.setProperty('object-position', 'left center', 'important'); // 画面整体靠左
              }

              // ================= 第二步：暴力找回全屏按钮 =================
              var allDivs = document.querySelectorAll('div');
              for (var j = 0; j < allDivs.length; j++) {
                var div = allDivs[j];
                var txt = div.innerText || '';
                // 1. 寻找包含“倍速”或时间格式的底部控制栏
                if ((txt.includes('倍速') || txt.match(/\d{2}:\d{2}/)) && div.offsetHeight < 200) {
                  div.style.setProperty('width', '100vw', 'important');
                  div.style.setProperty('box-sizing', 'border-box', 'important');
                  
                  // 🔥 关键修复：不加 padding，直接利用 right 强制把整个控制栏往左拉，露出右边的全屏按钮
                  div.style.setProperty('right', '0px', 'important'); 
                  div.style.setProperty('padding-right', '80px', 'important'); // 强行在右侧挤出一大块空间
                  
                  // 检查控制栏内部，强行唤醒全屏图标
                  var children = div.querySelectorAll('*');
                  for (var m = 0; m < children.length; m++) {
                    var child = children[m];
                    var title = child.getAttribute('title') || child.getAttribute('aria-label') || child.className || '';
                    // 如果找到带“全屏”或 "full" 字样的元素
                    if (title.toString().indexOf('全屏') > -1 || title.toString().indexOf('fullscreen') > -1 || title.toString().indexOf('full') > -1) {
                      child.style.setProperty('display', 'block', 'important');
                      child.style.setProperty('visibility', 'visible', 'important');
                      child.style.setProperty('opacity', '1', 'important');
                      child.style.setProperty('position', 'relative', 'important');
                      child.style.setProperty('right', '0', 'important');
                      child.style.setProperty('transform', 'none', 'important');
                    }
                  }
                }
              }
              
              // ================= 第三步：模拟鼠标移动 =================
              // 部分电脑版网页，控制栏需要鼠标移动才显示
              var event = new MouseEvent('mousemove', {
                  clientX: window.innerWidth / 2,
                  clientY: window.innerHeight - 50,
                  bubbles: true,
                  cancelable: true
              });
              document.dispatchEvent(event);
            }
            
            // 网页加载有延迟，多执行几次
            setTimeout(fixLayout, 800);
            setTimeout(fixLayout, 1500);
            setTimeout(fixLayout, 3000);

            // 4. 自动点击全屏（可选）
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
