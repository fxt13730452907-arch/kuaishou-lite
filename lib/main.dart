import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 加上了：状态栏完全透明，图标变白（沉浸式）
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
          // 绝对安全的单行拼接。
          // 1. 隐藏左侧边栏；2. 背景黑化；3. 视频宽度拉满；4. 滑动引擎。
          // 绝不碰全屏，绝不碰暂停。
          String js = "var s=document.createElement('style');s.innerHTML='aside,.sidebar,header,.header,[class*=header],[class*=nav]{display:none!important}body{background:#000!important;margin:0!important;overflow-x:hidden!important;}video{width:100vw!important;}';document.head.appendChild(s);var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var d=sy-e.changedTouches[0].clientY;if(Math.abs(d)>40){var w=new WheelEvent('wheel',{deltaY:(d>0?1:-1)*1000,bubbles:true});document.body.dispatchEvent(w);}},false);";
          _controller.runJavaScript(js);
        },
      ))
      ..loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 去掉 SafeArea，直接铺满，配合状态栏沉浸
      body: WebViewWidget(controller: _controller),
    );
  }
}
