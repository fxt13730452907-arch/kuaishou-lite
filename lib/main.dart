import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
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
    _controller = WebViewController();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    _controller.setMediaPlaybackRequiresUserGesture(false);
    _controller.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36");
    
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          _controller.runJavaScript(r"""
            // 1. 强制清理排版 (全屏、隐藏侧栏)
            var style = document.createElement('style');
            style.innerHTML = `
              aside, .sidebar, header, .header, .download-bar, 
              [class*="sidebar"], [class*="header"], [class*="nav"] { display: none !important; }
              main, .main, [class*="main"], [class*="content"] { width: 100vw !important; max-width: 100vw !important; padding: 0 !important; margin: 0 !important; left: 0 !important; }
              video, .video, [class*="video-player"], [class*="player"] { width: 100vw !important; height: 100vh !important; object-fit: cover !important; }
              ::-webkit-scrollbar { display: none !important; }
              /* 禁用网页默认的触摸拖拽 */
              body { touch-action: none !important; overflow: hidden !important; }
            `;
            document.head.appendChild(style);

            // 2. 强制解除静音
            function forceUnmute() {
                var videos = document.querySelectorAll('video');
                for (var i = 0; i < videos.length; i++) {
                    videos[i].muted = false;
                    videos[i].play().catch(function(e) {});
                }
            }
            forceUnmute();
            document.addEventListener('touchstart', forceUnmute, { once: true });
            setInterval(forceUnmute, 1500);

            // 3. 暴击滑动引擎：模拟鼠标滚轮 + 强行一滑一屏
            var startY = 0;
            var isScrolling = false;

            // passive: false 是解除网页触摸限制的关键
            document.addEventListener('touchstart', function(e) {
                startY = e.touches[0].clientY;
            }, {passive: false});

            // 拦截默认的触摸移动，防止网页内部拉扯
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
                    
                    // 核心绝招：在屏幕中间模拟一次鼠标滚轮 (Wheel Event)
                    // 因为网页版只认滚轮
                    var centerX = window.innerWidth / 2;
                    var centerY = window.innerHeight / 2;
                    var target = document.elementFromPoint(centerX, centerY) || document.body;
                    
                    var wheelEvent = new WheelEvent('wheel', {
                        deltaY: direction * 1000, // 滚动力度
                        bubbles: true,
                        cancelable: true,
                        clientX: centerX,
                        clientY: centerY
                    });
                    target.dispatchEvent(wheelEvent);

                    // 保险起见，同时也强行执行一次网页滚动
                    window.scrollBy({ top: direction * window.innerHeight * 0.8, behavior: 'smooth' });

                    // 0.5秒内禁止连续触发，防止跳过多条视频
                    setTimeout(function() { 
                        isScrolling = false; 
                        forceUnmute(); 
                    }, 500);
                }
            }, {passive: false});
          """);
        },
      ),
    );
    _controller.loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WebViewWidget(controller: _controller),
    );
  }
}
