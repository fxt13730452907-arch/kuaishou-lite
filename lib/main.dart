import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 沉浸状态栏（透明 + 白色图标）
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
      // 允许自动播放和正常声音
      ..setMediaPlaybackRequiresUserGesture(false)
      ..setUserAgent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36")
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // 绝对安全的单行字符串拼接，只做向左拉伸，不碰任何全屏和暂停逻辑
          String js = "";
          
          // 1. 基础黑化
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;margin:0!important;padding:0!important;overflow-x:hidden!important;}aside,.sidebar,header,.header{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 核心：干掉左侧占位黑条，将视频拉宽贴边
          js += "function ff(){";
          js += "document.body.style.setProperty('margin-left','0','important');document.body.style.setProperty('width','100vw','important');";
          
          // 精准狙击左侧占位长条（宽80-350，高大于屏幕60%，靠左）
          js += "var divs=document.querySelectorAll('div');for(var i=0;i<divs.length;i++){var el=divs[i];var r=el.getBoundingClientRect();if(r.left<=5&&r.width>80&&r.width<350&&r.height>window.innerHeight*0.6){el.style.setProperty('display','none','important');}}";
          
          // 找到视频，把父级容器拉满 100vw，绝不改变视频比例（不加 cover）
          js += "var v=document.querySelector('video');if(v){var p=v.parentElement;for(var k=0;k<4;k++){if(p){p.style.setProperty('width','100vw','important');p.style.setProperty('max-width','100vw','important');p.style.setProperty('margin','0 auto','important');p.style.setProperty('padding','0','important');p.style.setProperty('left','0','important');p.style.setProperty('transform','none','important');p=p.parentElement;}}";
          js += "v.style.setProperty('width','100vw','important');}";
          js += "}";
          
          js += "setTimeout(ff,1000);setTimeout(ff,2500);";
          
          // 3. 滑动引擎（滑动后重新拉宽一次，防止新视频复位）
          js += "var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},{passive:true});";
          js += "document.addEventListener('touchend',function(e){var d=sy-e.changedTouches[0].clientY;if(Math.abs(d)>40){var w=new WheelEvent('wheel',{deltaY:(d>0?1:-1)*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,800);}},{passive:true});";
          
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
