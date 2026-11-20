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
          // 极短单行代码，没有任何 += 拼接，只精准隐藏左侧大黑条，绝不改变视频原有大小
          _controller.runJavaScript("var s=document.createElement('style');s.innerHTML='html,body{background:#000!important;margin:0!important;overflow-x:hidden!important;}header,.header{display:none!important;}';document.head.appendChild(s);function ff(){var d=document.querySelectorAll('div');for(var i=0;i<d.length;i++){var r=d[i].getBoundingClientRect();if(r.left<10&&r.width>100&&r.width<400&&r.height>window.innerHeight*0.7){d[i].style.setProperty('display','none','important');}}}setTimeout(ff,1000);setTimeout(ff,2000);var sy=0;document.addEventListener('touchstart',function(e){sy=e.touches[0].clientY;},false);document.addEventListener('touchend',function(e){var ey=e.changedTouches[0].clientY;var diff=sy-ey;if(Math.abs(diff)>40){var w=new WheelEvent('wheel',{deltaY:(diff>0?1:-1)*1000,bubbles:true});document.body.dispatchEvent(w);setTimeout(ff,500);}},false);");
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
