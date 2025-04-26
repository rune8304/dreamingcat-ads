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

  final List<String> categories = ['전체', '비', '바다', '바람', '불', '풀벌레', '도시'];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadBannerAd();
    _loadLatestYoutubeVideo();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteVideoUrls = prefs.getStringList('favorites') ?? [];
    });
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
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
      String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildCategoryButton(
      String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color.fromARGB(255, 59, 181, 238)
            : Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(label),
    );
  }

  Widget _buildGridTile(Map<String, dynamic> video) {
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Image.network(
              video['thumbnail'] ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                padding: const EdgeInsets.all(8),
                child: Text(
                  video['title'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(
                  favoriteVideoUrls.contains(video['videoUrl'])
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.pinkAccent,
                ),
                onPressed: () => _toggleFavorite(video['videoUrl'] ?? ''),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[850],
        ),
        child: Center(
          // ✅ 추가
          child: Container(
            // ✅ 묶어야 진짜 중앙된다
            constraints: const BoxConstraints(
                maxWidth: 300), // ✅ 약간 크기 제한 주기 (너무 퍼지지 않게)
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    video['thumbnail'] ?? '',
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      video['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video['description'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            const Text('꿈꾸는고양이', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('v1.0.1',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4), fontSize: 12)),
          ],
        ),
        actions: [
          Row(
            children: [
              _buildControlButton(
                showFavoritesOnly ? 'favorit❤️' : 'favorit',
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
          Container(
            width: double.infinity,
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Center(
              child: Text(
                'youtube 최신 업로드 영상',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          GestureDetector(
            onTap: _launchYoutube,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 98, 101, 105),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // ✅ Row를 중앙정렬!
                children: [
                  Container(
                      constraints: const BoxConstraints(
                        maxWidth: 320, // ✅ 썸네일+텍스트 묶음의 최대 너비를 고정
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center, // ✅ Row 중앙정렬 유지
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              latestYoutubeVideo?['thumbnailUrl'] ?? '',
                              width: 120,
                              height: 68,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expanded 없애고 SizedBox로 감싸
                          SizedBox(
                            width: 130, // 💡 텍스트 박스 가로폭 제한 (조정 가능)
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  latestYoutubeVideo?['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  latestYoutubeVideo?['description'] ?? '',
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
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
                          childAspectRatio: 16 / 9,
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
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
