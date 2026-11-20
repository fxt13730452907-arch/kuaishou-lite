import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
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
          // 使用极简拼接，绝对不会报错
          String js = "";
          
          // 1. 隐藏左侧栏和顶部，黑化背景
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;overflow-x:hidden!important;}aside,.sidebar,header,.header{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 延迟 3 秒，等视频完全加载后，自动点击全屏按钮
          js += "setTimeout(function(){";
          js += "var els=document.querySelectorAll('div,span,svg,path,i,button');"; // 搜索所有可能的元素
          js += "for(var i=0;i<els.length;i++){";
          js += "var el=els[i];var title=el.getAttribute('title')||el.getAttribute('aria-label')||'';var cls=el.className||'';";
          // 只要标题里带“全屏”，或者 class 里带 fullscreen，直接点它
          js += "if(title.indexOf('全屏')>-1||title.indexOf('fullscreen')>-1||cls.toString().indexOf('fullscreen')>-1){";
          js += "el.click();break;"; 
          js += "}}},3000);"; // 延迟 3 秒执行

          // 3. 滑动引擎
          js += "var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var ey=e.changedTouches[0].clientY;var d=sy-ey;if(Math.abs(d)>40){var dir=d>0?1:-1;var w=new WheelEvent('wheel',{deltaY:dir*1000,bubbles:true});document.body.dispatchEvent(w);}},false);";
          
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
