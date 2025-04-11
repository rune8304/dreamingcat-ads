import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  List<String> favoriteVideoIds = [];

  final List<String> categories = ['전체', '비', '파도', '장작', '엔진', '풀벌레'];

  final BannerAd _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-7625356414808879/2062467221',
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  );

  @override
  void initState() {
    super.initState();
    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('videos')
              .orderBy('order', descending: false)
              .orderBy('createdAt', descending: false)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('에러 발생: ${snapshot.error}')),
          );
        }

        final videoDocs = snapshot.data?.docs ?? [];
        final allVideos =
            videoDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final url = data['url'] ?? '';
              final videoId = Uri.tryParse(url)?.queryParameters['v'] ?? '';
              return {
                'title': data['title'] ?? '',
                'videoId': videoId,
                'thumbnail': data['thumbnail'] ?? '',
                'category': data['category'] ?? '',
              };
            }).toList();

        final baseFilteredVideos =
            selectedCategory == '전체'
                ? allVideos
                : allVideos
                    .where((v) => v['category'] == selectedCategory)
                    .toList();

        final filteredVideos =
            showFavoritesOnly
                ? baseFilteredVideos
                    .where((v) => favoriteVideoIds.contains(v['videoId']))
                    .toList()
                : baseFilteredVideos;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '꿈꾸는고양이',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pinkAccent,
                ),
                onPressed: () {
                  setState(() {
                    showFavoritesOnly = !showFavoritesOnly;
                  });
                },
              ),
              IconButton(
                icon: Icon(isGrid ? Icons.list : Icons.grid_view),
                onPressed: () {
                  setState(() {
                    isGrid = !isGrid;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 타이틀 및 배경 이미지
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: Image.asset(
                      'assets/night_sky_header.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '고요한 밤, 오늘도 수고했어요❤️',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 카테고리 선택 바
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children:
                      categories.map((category) {
                        final isSelected = selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (_) {
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
              // 영상 리스트
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 16 / 14,
                  ),
                  itemCount: filteredVideos.length,
                  itemBuilder: (context, index) {
                    final video = filteredVideos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => VideoPlayerScreen(
                                  videoId: video['videoId']!,
                                  title: video['title']!,
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
                              errorBuilder:
                                  (context, error, stackTrace) => const Center(
                                    child: Icon(Icons.broken_image),
                                  ),
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
                                  favoriteVideoIds.contains(video['videoId'])
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.pinkAccent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    final id = video['videoId']!;
                                    if (favoriteVideoIds.contains(id)) {
                                      favoriteVideoIds.remove(id);
                                    } else {
                                      favoriteVideoIds.add(id);
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 배너 광고 표시 부분
              if (_bannerAd != null)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd.size.width.toDouble(),
                  height: _bannerAd.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd),
                ),
            ],
          ),
        );
      },
    );
  }
}
