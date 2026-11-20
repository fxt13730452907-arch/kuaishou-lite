import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 开启沉浸式状态栏（透明背景 + 白色图标）
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
          // 安全单行拼接，防止编译器崩溃
          String js = "";
          
          // 1. 基础黑化，干掉左侧导航和顶部
          js += "var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;overflow-x:hidden!important;margin:0!important;padding:0!important;}aside,.sidebar,header,.header,[class*=header],[class*=nav]{display:none!important;}';document.head.appendChild(s);";
          
          // 2. 清理、防黑屏补丁、防暂停、强制发声
          js += "function ff(){";
          js += "document.body.style.setProperty('margin-left','0','important');document.body.style.setProperty('width','100vw','important');";
          
          // 干掉左侧长条和静音提示框
          js += "var divs=document.querySelectorAll('div');for(var i=0;i<divs.length;i++){var el=divs[i];var r=el.getBoundingClientRect();if(r.left<=5&&r.width>80&&r.width<350&&r.height>window.innerHeight*0.6){el.style.setProperty('display','none','important');}}";
          js += "var all=document.querySelectorAll('*');for(var j=0;j<all.length;j++){var n=all[j];if(n.childNodes.length>0&&n.childNodes[0].nodeType===3){var t=n.childNodes[0].nodeValue;if(t&&(t.indexOf('打开声音')>-1||t.indexOf('静音')>-1)){n.style.setProperty('display','none','important');if(n.parentElement)n.parentElement.style.setProperty('display','none','important');}}}";
          
          // 【修复黑屏】给全屏按钮添加点击拦截，点击后强制重新铺满，防止画面丢失
          js += "var btns=document.querySelectorAll('div,span,button,svg');for(var b=0;b<btns.length;b++){var el=btns[b];var title=el.getAttribute('title')||el.getAttribute('aria-label')||'';if(title.indexOf('全屏')>-1||title.indexOf('fullscreen')>-1){el.onclick=function(e){setTimeout(ff,100);setTimeout(ff,500);};}}";
          
          // 核心拉宽铺满
          js += "var v=document.querySelector('video');if(v){var p=v.parentElement;for(var k=0;k<5;k++){if(p){p.style.setProperty('width','100vw','important');p.style.setProperty('max-width','100vw','important');p.style.setProperty('margin','0','important');p.style.setProperty('padding','0','important');p.style.setProperty('left','0','important');p.style.setProperty('transform','none','important');p=p.parentElement;}}";
          js += "v.style.setProperty('width','100vw','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');";
          
          // 【修复暂停】监听暂停，强制恢复
          js += "v.onpause=function(){if(v.currentTime<v.duration){setTimeout(function(){v.play().catch(function(e){});},50);}};";
          
          // 强制解除静音
          js += "v.muted=false;v.play().catch(function(e){});}";
          js += "}";
          
          // 3. 延迟执行
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
