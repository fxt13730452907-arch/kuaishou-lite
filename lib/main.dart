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
          // 安全单行拼接，彻底避开 AOT 编译器崩溃
          String js = "var s=document.createElement('style');s.innerHTML='aside,.sidebar,header,.header,[class*=header],[class*=nav]{display:none!important}body{background:#000!important;margin:0!important;overflow:hidden!important;}video{width:100vw!important;height:100vh!important;object-fit:cover!important;}';document.head.appendChild(s);try{Element.prototype.requestFullscreen=function(){};document.documentElement.requestFullscreen=function(){};}catch(e){}function ff(){var v=document.querySelector('video');if(v){v.style.setProperty('width','100vw','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');v.style.setProperty('margin','0','important');}}setTimeout(ff,1000);setTimeout(ff,2000);var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var d=sy-e.changedTouches[0].clientY;if(Math.abs(d)>40){var w=new WheelEvent('wheel',{deltaY:(d>0?1:-1)*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,500);}},false);";
          _controller.runJavaScript(js);
        },
      ))
      ..loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 直接铺满，去掉安全区
      body: WebViewWidget(controller: _controller),
    );
  }
}
