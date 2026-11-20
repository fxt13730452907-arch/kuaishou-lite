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
      ..setMediaPlaybackRequiresUserGesture(false) // 允许自动播放
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // 极其安全的单行长字符串，完全避开编译器 Bug
          String js = "var s=document.createElement('style');s.innerHTML='aside,.sidebar,header,.header{display:none!important}body{background:#000!important;margin:0!important;overflow:hidden!important;}';document.head.appendChild(s);function ff(){var v=document.querySelector('video');if(v){v.style.setProperty('width','100vw','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');v.style.setProperty('margin','0','important');var p=v.parentElement;if(p){p.style.setProperty('width','100vw','important');p.style.setProperty('margin','0','important');p.style.setProperty('padding','0','important');}}}try{Element.prototype.requestFullscreen=function(){};document.documentElement.requestFullscreen=function(){};}catch(e){}setTimeout(ff,1000);setTimeout(ff,2000);var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var ey=e.changedTouches[0].clientY;var d=sy-ey;if(Math.abs(d)>40){var dir=d>0?1:-1;var w=new WheelEvent('wheel',{deltaY:dir*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,500);}},false);";
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
