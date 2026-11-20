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
    _controller = WebViewController();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    // 允许自动播放
    _controller.setMediaPlaybackRequiresUserGesture(false);
    _controller.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36");
    
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          // 注入优化代码（去掉了反引号，确保绝对能编译通过）
          _controller.runJavaScript("""
            // 1. 隐藏左侧边栏、顶部栏，强制满屏
            var style = document.createElement('style');
            style.innerHTML = 'aside, .sidebar, header, .header, .download-bar, [class*="sidebar"], [class*="nav"] { display: none !important; } main, .main, [class*="main"], [class*="content"] { width: 100vw !important; max-width: 100vw !important; padding: 0 !important; margin: 0 !important; left: 0 !important; } video, .video, [class*="video-player"] { width: 100vw !important; height: 100vh !important; object-fit: cover !important; } ::-webkit-scrollbar { display: none !important; } body { background: #000 !important; }';
            document.head.appendChild(style);

            // 2. 强制解除静音并播放
            function forceUnmute() {
                var videos = document.querySelectorAll('video');
                for (var i = 0; i < videos.length; i++) {
                    videos[i].muted = false;
                    var p = videos[i].play();
                    if (p !== undefined) { p.catch(function(e) {}); }
                }
            }
            forceUnmute();
            setInterval(forceUnmute, 1500);

            // 3. 接管滑动手势，一滑一屏
            var startY = 0;
            var isScrolling = false;
            document.addEventListener('touchstart', function(e) {
                startY = e.touches[0].clientY;
            }, {passive: true});

            document.addEventListener('touchend', function(e) {
                var endY = e.changedTouches[0].clientY;
                var distance = startY - endY;
                if (Math.abs(distance) > 40 && !isScrolling) {
                    isScrolling = true;
                    var direction = distance > 0 ? 1 : -1;
                    window.scrollBy({ top: direction * window.innerHeight * 0.8, behavior: 'smooth' });
                    setTimeout(function() { isScrolling = false; forceUnmute(); }, 500);
                }
            }, {passive: true});
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
      // 直接全屏
      body: WebViewWidget(controller: _controller),
    );
  }
}
