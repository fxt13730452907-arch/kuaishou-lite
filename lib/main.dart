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
      title: '快手纯净版',
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            
            // 注入 CSS 与 JS
            _controller.runJavaScript("""
              // 强制宽度铺满
              var meta = document.querySelector('meta[name="viewport"]');
              if (!meta) {
                meta = document.createElement('meta');
                meta.name = 'viewport';
                document.head.appendChild(meta);
              }
              meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
              document.body.style.backgroundColor = '#000000';
              
              // 隐藏多余元素
              var style = document.createElement('style');
              style.innerHTML = 'header, .header, .sidebar, .nav-bar, .download-bar { display: none !important; } body, html { width: 100% !important; margin: 0 !important; padding: 0 !important; overflow-x: hidden; } div[class*="video"] { max-width: 100vw !important; }';
              document.head.appendChild(style);

              // 强制解除静音并播放
              function unmuteAndPlay() {
                  var videos = document.querySelectorAll('video');
                  for (var i = 0; i < videos.length; i++) {
                      videos[i].muted = false;
                      videos[i].play().catch(function(e) {});
                  }
              }
              unmuteAndPlay();
              document.addEventListener('touchstart', unmuteAndPlay, { once: true });
              setInterval(unmuteAndPlay, 1500);

              // 注入手势拦截，一滑一屏
              var startY = 0;
              document.addEventListener('touchstart', function(e) {
                  startY = e.touches[0].clientY;
              }, {passive: true});

              document.addEventListener('touchend', function(e) {
                  var endY = e.changedTouches[0].clientY;
                  var distance = startY - endY;
                  if (Math.abs(distance) > 50) {
                      if (distance > 0) {
                          window.scrollBy({ top: window.innerHeight * 0.85, behavior: 'smooth' });
                      } else {
                          window.scrollBy({ top: -window.innerHeight * 0.85, behavior: 'smooth' });
                      }
                      setTimeout(unmuteAndPlay, 500);
                  }
              }, {passive: true});
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          _controller.goBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
