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
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // 使用安全的拼接方式，避免任何特殊字符导致编译器崩溃
          String js = ""
            "var s=document.createElement('style');"
            "s.innerHTML='html,body{background:#000!important;overflow:hidden!important;margin:0!important;padding:0!important;}"
            "header,.header,aside,.sidebar,[class*=header],[class*=nav]{display:none!important;}"
            "video{width:100vw!important;height:100vh!important;object-fit:cover!important;}"
            "';"
            "document.head.appendChild(s);"
            "var startY=0;"
            "document.addEventListener('touchstart',function(e){startY=e.touches[0].clientY;},false);"
            "document.addEventListener('touchend',function(e){"
            "var endY=e.changedTouches[0].clientY;"
            "var d=startY-endY;"
            "if(Math.abs(d)>40){"
            "var dir=d>0?1:-1;"
            "var wheel=new WheelEvent('wheel',{deltaY:dir*1000,bubbles:true});"
            "document.body.dispatchEvent(wheel);"
            "}"
            "},false);";
            
          _controller.runJavaScript(js);
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
