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
          // 使用绝对安全的单行拼接，防止 Flutter AOT 编译器崩溃
          String js = "";
          
          // 1. 基础黑化，干掉左侧导航和顶部
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;overflow-x:hidden!important;margin:0!important;padding:0!important;}aside,.sidebar,header,.header,[class*=header],[class*=nav]{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 清理与强制向左靠齐并铺满
          js += "function ff(){";
          // 强行把 body 贴死左边
          js += "document.body.style.setProperty('margin-left','0','important');document.body.style.setProperty('width','100vw','important');";
          
          // 干掉左侧占位长条
          js += "var divs=document.querySelectorAll('div');for(var i=0;i<divs.length;i++){var el=divs[i];var r=el.getBoundingClientRect();if(r.left<=5&&r.width>80&&r.width<350&&r.height>window.innerHeight*0.6){el.style.setProperty('display','none','important');}}";
          
          // 干掉恶心的静音提示框
          js += "var all=document.querySelectorAll('*');for(var j=0;j<all.length;j++){var n=all[j];if(n.childNodes.length>0&&n.childNodes[0].nodeType===3){var t=n.childNodes[0].nodeValue;if(t&&(t.indexOf('打开声音')>-1||t.indexOf('静音')>-1)){n.style.setProperty('display','none','important');if(n.parentElement)n.parentElement.style.setProperty('display','none','important');}}}";
          
          // 核心：暴力把视频及其父级拉宽贴边
          js += "var v=document.querySelector('video');if(v){var p=v.parentElement;for(var k=0;k<5;k++){if(p){p.style.setProperty('width','100vw','important');p.style.setProperty('max-width','100vw','important');p.style.setProperty('margin','0','important');p.style.setProperty('padding','0','important');p.style.setProperty('left','0','important');p.style.setProperty('transform','none','important');p=p.parentElement;}}";
          js += "v.style.setProperty('width','100vw','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');";
          // 尝试解除静音
          js += "v.muted=false;v.play().catch(function(e){});}";
          js += "}";
          
          // 3. 延迟执行，确保视频加载
          js += "setTimeout(ff,1000);setTimeout(ff,2500);";
          
          // 4. 滑动引擎
          js += "var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var ey=e.changedTouches[0].clientY;var d=sy-ey;if(Math.abs(d)>40){var dir=d>0?1:-1;var w=new WheelEvent('wheel',{deltaY:dir*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,1000);}},false);";
          
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
