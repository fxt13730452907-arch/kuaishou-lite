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
          // 极度安全的单行拼接。只做两件事：清理左侧占位，不改变视频比例！
          String js = "";
          
          // 1. 全局背景黑化，消除滚动条
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;margin:0!important;overflow-x:hidden!important;}header,.header{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 只干掉左侧占用空间的黑色长条（绝不碰视频宽度）
          js += "function ff(){";
          js += "var divs=document.querySelectorAll('div,aside,nav');";
          js += "for(var i=0;i<divs.length;i++){";
          js += "var el=divs[i];var r=el.getBoundingClientRect();";
          // 精准击杀：只要它在最左边，且宽度在 80-350 之间，高度占据屏幕一大半，直接隐藏
          js += "if(r.left<=5&&r.width>80&&r.width<350&&r.height>window.innerHeight*0.6){el.style.setProperty('display','none','important');}";
          js += "}}";
          
          js += "setTimeout(ff,1000);setTimeout(ff,2500);";
          
          // 3. 滑动引擎（滑动后重新检查一遍左侧边栏）
          js += "var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},{passive:true});";
          js += "document.addEventListener('touchend',function(e){var d=sy-e.changedTouches[0].clientY;if(Math.abs(d)>40){var w=new WheelEvent('wheel',{deltaY:(d>0?1:-1)*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,500);}},{passive:true});";
          
          _controller.runJavaScript(js);
        },
      ))
      ..loadRequest(Uri.parse('https://www.kuaishou.com/new-reco'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 不用 SafeArea，让状态栏直接沉浸
      body: WebViewWidget(controller: _controller),
    );
  }
}
