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
          // 严格使用单行拼接，绝不报错
          String js = "";
          
          // 1. 全局基础设置
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;overflow:hidden!important;margin:0!important;padding:0!important;}aside,.sidebar,header,.header{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 核心：暴力推拉去黑边
          js += "function ff(){";
          // 整个页面向左拉，并加宽
          js += "document.body.style.setProperty('margin-left','-20px','important');document.body.style.setProperty('width','calc(100vw + 20px)','important');";
          
          // 干掉左侧边栏
          js += "var divs=document.querySelectorAll('div');for(var i=0;i<divs.length;i++){var el=divs[i];var r=el.getBoundingClientRect();if(r.left<=5&&r.width>80&&r.width<350&&r.height>window.innerHeight*0.6){el.style.setProperty('display','none','important');}}";
          
          // 干掉静音提示框
          js += "var all=document.querySelectorAll('*');for(var j=0;j<all.length;j++){var n=all[j];if(n.childNodes.length>0&&n.childNodes[0].nodeType===3){var t=n.childNodes[0].nodeValue;if(t&&(t.indexOf('打开声音')>-1||t.indexOf('静音')>-1)){n.style.setProperty('display','none','important');if(n.parentElement)n.parentElement.setProperty('display','none','important');}}}";
          
          // 视频和它的父级：强行增加宽度并向左偏移
          js += "var v=document.querySelector('video');if(v){";
          // 视频宽度多 40px，左移 20px
          js += "v.style.setProperty('width','calc(100vw + 40px)','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');v.style.setProperty('margin-left','-20px','important');";
          // 向上找 6 层父级，全部一并拉宽向左移
          js += "var p=v.parentElement;for(var k=0;k<6;k++){if(p){p.style.setProperty('width','calc(100vw + 40px)','important');p.style.setProperty('margin-left','-20px','important');p.style.setProperty('max-width','none','important');p.style.setProperty('left','0','important');p.style.setProperty('transform','none','important');p=p.parentElement;}}";
          // 尝试发声
          js += "v.muted=false;v.play().catch(function(e){});}";
          js += "}";
          
          // 3. 定时执行，确保加载完毕
          js += "setTimeout(ff,1000);setTimeout(ff,2000);setTimeout(ff,3000);";
          
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
