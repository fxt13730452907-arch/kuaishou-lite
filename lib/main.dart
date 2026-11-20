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
          // 绝杀：把所有 JS 压缩成单行，彻底解决编译器崩溃问题
          String js = "var style=document.createElement('style');style.innerHTML='html,body{background:#000 !important;overflow-x:hidden !important;margin:0 !important;padding:0 !important;}header,.header,[class*=\"header\"],[class*=\"nav\"]{display:none !important;}aside,.sidebar{display:none !important;}';document.head.appendChild(style);function cleanPage(){document.body.style.setProperty('margin-left','0','important');document.body.style.setProperty('width','100vw','important');var divs=document.querySelectorAll('div');for(var i=0;i<divs.length;i++){var el=divs[i];var rect=el.getBoundingClientRect();if(rect.left<=5&&rect.width>80&&rect.width<350&&rect.height>window.innerHeight*0.6){el.style.setProperty('display','none','important');}}var allElements=document.querySelectorAll('*');for(var j=0;j<allElements.length;j++){var e=allElements[j];if(e.childNodes.length>0&&e.childNodes[0].nodeType===3){var txt=e.childNodes[0].nodeValue;if(txt&&(txt.indexOf('空格')>-1||txt.indexOf('暂停')>-1||txt.indexOf('静音')>-1||txt.indexOf('打开声音')>-1)){e.style.setProperty('display','none','important');if(e.parentElement)e.parentElement.style.setProperty('display','none','important');}}}var v=document.querySelector('video');if(v){var p=v;for(var k=0;k<4;k++){if(p){p.style.setProperty('width','100vw','important');p.style.setProperty('max-width','100vw','important');p.style.setProperty('margin','0 auto','important');p.style.setProperty('padding','0','important');p.style.setProperty('left','0','important');p=p.parentElement;}}v.style.setProperty('width','100vw','important');v.style.setProperty('height','100vh','important');v.style.setProperty('object-fit','cover','important');v.muted=false;v.play().catch(function(e){});}}setTimeout(cleanPage,1000);setTimeout(cleanPage,2500);setInterval(cleanPage,3000);setTimeout(function(){var hEvent=new KeyboardEvent('keydown',{key:'h',code:'KeyH',keyCode:72,which:72,bubbles:true,cancelable:true});document.dispatchEvent(hEvent);document.body.dispatchEvent(hEvent);},3500);var startY=0;document.addEventListener('touchstart',function(e){startY=e.touches[0].clientY;},{passive:true});document.addEventListener('touchend',function(e){var endY=e.changedTouches[0].clientY;var distance=startY-endY;if(Math.abs(distance)>40){var direction=distance>0?1:-1;var centerX=window.innerWidth/2;var centerY=window.innerHeight/2;var target=document.elementFromPoint(centerX,centerY)||document.body;var wheelEvent=new WheelEvent('wheel',{deltaY:direction*1000,bubbles:true,cancelable:true,clientX:centerX,clientY:centerY});target.dispatchEvent(wheelEvent);}},{passive:true});";
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
