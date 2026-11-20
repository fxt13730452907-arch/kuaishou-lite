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
          String js = "";
          
          // 1. 基础清理
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;margin:0!important;padding:0!important;overflow:hidden!important;}aside,.sidebar,header{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 防全屏黑屏补丁（保留按钮，拦截底层API）
          js += "try{Element.prototype.requestFullscreen=function(){};document.documentElement.requestFullscreen=function(){};}catch(e){}";
          
          // 3. 核心：强制物理覆盖
          js += "function ff(){";
          js += "var v=document.querySelector('video');if(v){";
          
          // 向上找三层父节点，直接全屏钉死在最上层！
          js += "var p=v.parentElement;for(var i=0;i<3;i++){if(p){";
          js += "p.style.setProperty('position','fixed','important');";
          js += "p.style.setProperty('top','0','important');";
          js += "p.style.setProperty('left','0','important');";
          js += "p.style.setProperty('width','100vw','important');";
          js += "p.style.setProperty('height','100vh','important');";
          js += "p.style.setProperty('z-index','9999','important');";
          js += "p.style.setProperty('margin','0','important');";
          js += "p.style.setProperty('padding','0','important');";
          js += "p=p.parentElement;}}";
          
          // 视频铺满
          js += "v.style.setProperty('width','100vw','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');}";
          
          // 自动点击“打开声音”，顺滑解禁（绝不影响暂停）
          js += "var all=document.querySelectorAll('*');for(var j=0;j<all.length;j++){var n=all[j];if(n.childNodes.length>0&&n.childNodes[0].nodeType===3){var t=n.childNodes[0].nodeValue;if(t&&t.indexOf('打开声音')>-1){n.parentElement.click();}}}";
          
          js += "}";
          
          js += "setTimeout(ff,1000);setTimeout(ff,2500);";
          
          // 4. 滑动引擎
          js += "var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var ey=e.changedTouches[0].clientY;var d=sy-ey;if(Math.abs(d)>40){var dir=d>0?1:-1;var w=new WheelEvent('wheel',{deltaY:dir*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,800);}},false);";
          
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
