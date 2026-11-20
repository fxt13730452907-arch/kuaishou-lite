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
    _controller.setMediaPlaybackRequiresUserGesture(false);
    _controller.setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36");
    
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (String url) {
          // 将 JS 压缩成极其紧凑的单行字符串，不给编译器留任何报错的机会
          String js = "var s=document.createElement('style');s.innerHTML='aside,header,.header,.sidebar,.download-bar,[class*=sidebar]{display:none!important}main,[class*=main],body{width:100vw!important;margin:0!important;padding:0!important;background:#000}video{width:100vw!important;height:100vh!important;object-fit:cover!important}';document.head.appendChild(s);function u(){var v=document.querySelectorAll('video');for(var i=0;i<v.length;i++){v[i].muted=false;v[i].play().catch(function(e){})}}u();setInterval(u,1500);var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY},{passive:true});document.addEventListener('touchend',function(e){var ey=e.changedTouches[0].clientY;var d=sy-ey;if(Math.abs(d)>40){if(d>0){window.scrollBy({top:window.innerHeight*0.8,behavior:'smooth'})}else{window.scrollBy({top:-window.innerHeight*0.8,behavior:'smooth'})}setTimeout(u,500)}},{passive:true});";
          _controller.runJavaScript(js);
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
