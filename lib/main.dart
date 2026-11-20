import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kuaishou Lite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const FeedPage(),
    );
  }
}

class VideoItem {
  final String id;
  final String url;
  final String author;
  final String caption;
  VideoItem({required this.id, required this.url, required this.author, required this.caption});
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PageController _pageController = PageController();
  final List<VideoItem> _videos = [
    VideoItem(id: '1', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4', author: '@kuaishou_lite', caption: '第一条测试视频，单击暂停，双击点赞。'),
    VideoItem(id: '2', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4', author: '@demo_user', caption: '上下滑动切换视频。'),
    VideoItem(id: '3', url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4', author: '@flutter', caption: '快手轻量版 MVP 跑起来了！'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final isActive = index == (_pageController.page?.round() ?? 0);
          return FeedPageItem(video: _videos[index], isActive: isActive);
        },
      ),
    );
  }
}

class FeedPageItem extends StatefulWidget {
  final VideoItem video;
  final bool isActive;
  const FeedPageItem({super.key, required this.video, required this.isActive});
  @override
  State<FeedPageItem> createState() => _FeedPageItemState();
}

class _FeedPageItemState extends State<FeedPageItem> {
  late final Player _player;
  late final VideoController _controller;
  
  bool _showHeart = false;
  Offset _heartPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _player.open(Media(widget.video.url), play: widget.isActive);
    _player.setPlaylistMode(PlaylistMode.loop);
  }

  @override
  void didUpdateWidget(covariant FeedPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _player.play();
    } else if (oldWidget.isActive && !widget.isActive) {
      _player.pause();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _triggerHeartAnimation(Offset position) {
    setState(() {
      _showHeart = true;
      _heartPosition = position;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_player.state.playing) {
              _player.pause();
            } else {
              _player.play();
            }
          },
          onDoubleTapDown: (details) {
            _triggerHeartAnimation(details.localPosition);
          },
          onDoubleTap: () {}, 
          child: Video(controller: _controller, fit: BoxFit.cover),
        ),
        
        if (_showHeart)
          Positioned(
            left: _heartPosition.dx - 40,
            top: _heartPosition.dy - 40,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value * 1.5,
                    child: Opacity(opacity: 1.0 - value, child: const Icon(Icons.favorite, color: Colors.red, size: 80)),
                  );
                },
              ),
            ),
          ),

        Positioned(
          left: 16, right: 80, bottom: 48,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.video.author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text(widget.video.caption, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
