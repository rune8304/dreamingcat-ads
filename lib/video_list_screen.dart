import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_screen.dart';

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  String selectedCategory = '전체';
  bool isGrid = true;
  bool showFavoritesOnly = false;
  List<String> favoriteVideoUrls = [];
  BannerAd? _bannerAd;
  Map<String, dynamic>? latestYoutubeVideo;
  bool _isUpdateDialogShown = false; // ✅ 추가

  final List<String> categories = ['전체', '비', '바다', '바람', '불', '풀벌레', '도시'];

  @override
  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadBannerAd();
    _loadLatestYoutubeVideo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowUpdateDialog(); // ✅ 최초 1회만 띄우는 함수 호출
    });
  }

  void _checkAndShowUpdateDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('update_dialog_shown') ?? false;

    if (!hasShown) {
      _showUpdateDialog();
      await prefs.setBool('update_dialog_shown', true); // ✅ 최초 1회만 표시
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B).withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Center(
          child: Text(
            '업데이트 안내',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        content: const Text(
          '이번 업데이트:\n\n- 앱 ui 전면 개선 \n- 백그라운드 재생 안정화\n- 타이머 시간 조절 기능 추가',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteVideoUrls = prefs.getStringList('favorites') ?? [];
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-7625356414808879/3876215538',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(),
    )..load();
  }

  Future<void> _loadLatestYoutubeVideo() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('youtube')
        .doc('newvideo')
        .get();
    if (snapshot.exists) {
      setState(() {
        latestYoutubeVideo = snapshot.data();
      });
    }
  }

  Future<void> _toggleFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (favoriteVideoUrls.contains(url)) {
        favoriteVideoUrls.remove(url);
      } else {
        favoriteVideoUrls.add(url);
      }
      prefs.setStringList('favorites', favoriteVideoUrls);
    });
  }

  Future<void> _launchYoutube() async {
    if (latestYoutubeVideo != null &&
        latestYoutubeVideo!['youtubeUrl'] != null) {
      final url = Uri.parse(latestYoutubeVideo!['youtubeUrl']);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  Widget _buildControlButton(
    String label,
    bool isSelected,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF583AC5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF7E62E2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
          minimumSize: Size.zero, // ✅ 최소 크기 제한 제거
          tapTargetSize: MaterialTapTargetSize.shrinkWrap, // ✅ 터치 영역 최소화
          visualDensity: VisualDensity.compact, // ✅ 여백 압축
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildCategoryButton(
      String label, bool isSelected, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(4),
      height: 48,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF583AC5) : const Color(0xFF7E62E2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4C4565),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          foregroundColor: Colors.white,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(Map<String, dynamic> video) {
    return InkWell(
      onTap: () {
        print("✅ GridTile tapped: ${video['title']}"); // 디버깅용
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: video['videoUrl'] ?? '',
              title: video['title'] ?? '',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 96, 95, 97),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 4,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  video['thumbnail'] ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF7E62E2),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        video['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      favoriteVideoUrls.contains(video['videoUrl'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.pinkAccent,
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(video['videoUrl'] ?? ''),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: video['videoUrl'] ?? '',
              title: video['title'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF7E62E2), // 박스 배경색
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6), // 그림자 색상
              blurRadius: 8, // 그림자 퍼짐 정도
              offset: const Offset(4, 4), // x, y 방향
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Image.network(
                video['thumbnail'] ?? '',
                width: 120,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      video['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      favoriteVideoUrls.contains(video['videoUrl'])
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Colors.pinkAccent,
                    ),
                    onPressed: () => _toggleFavorite(video['videoUrl'] ?? ''),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4C4565),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2938),
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center, // ✅ 하단 정렬
          children: [
            const Text(
              '꿈꾸는고양이',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              'v1.0.2',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              _buildControlButton(
                showFavoritesOnly ? 'favorit❤️' : 'favorit🤍',
                showFavoritesOnly,
                () {
                  setState(() {
                    showFavoritesOnly = !showFavoritesOnly;
                  });
                },
              ),
              const SizedBox(width: 8),
              _buildControlButton(
                isGrid ? 'view📷' : 'view📄',
                false,
                () {
                  setState(() {
                    isGrid = !isGrid;
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () async {
              const url = 'https://www.youtube.com/@asmr-dreamcat';
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              }
            },
            child: Material(
              color: const Color.fromARGB(255, 56, 48, 87),
              child: InkWell(
                splashColor: Colors.white24,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '꿈꾸는 고양이 youtube 놀러가기',
                            style: TextStyle(
                              color: Color(0xFFF9F2E8),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '여러분의 구독과 좋아요는 힘이 됩니다',
                            style: TextStyle(
                              color: Color(0xCCF9F2E8),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFF583AC5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'CLICK',
                              style: TextStyle(
                                color: Color(0xFFF9F2E8),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        left: 0,
                        child: Image.asset(
                          'assets/youtube.png',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2D2938), // 원하는 배경색 (예: 하늘색 계열)
            ),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: categories.map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildCategoryButton(
                      category,
                      isSelected,
                      () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('videos').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }

                final videoDocs = snapshot.data?.docs ?? [];
                final allVideos = videoDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'title': data['title'] ?? '',
                    'videoUrl': data['url'] ?? '',
                    'thumbnail': data['thumbnail'] ?? '',
                    'category': (data['category'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase(),
                  };
                }).toList();

                final baseFilteredVideos = selectedCategory == '전체'
                    ? allVideos
                    : allVideos
                        .where((v) =>
                            v['category'] ==
                            selectedCategory.trim().toLowerCase())
                        .toList();

                final filteredVideos = showFavoritesOnly
                    ? baseFilteredVideos
                        .where((v) => favoriteVideoUrls.contains(v['videoUrl']))
                        .toList()
                    : baseFilteredVideos;

                return isGrid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 17 / 13,
                        ),
                        itemCount: filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = filteredVideos[index];
                          return _buildGridTile(video);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredVideos.length,
                        itemBuilder: (context, index) {
                          final video = filteredVideos[index];
                          return _buildListTile(video);
                        },
                      );
              },
            ),
          ),
          if (_bannerAd != null)
            Container(
              width: double.infinity,
              color: const Color(0xFF2D2938), // ✅ 피그마 하단 배경색
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
