import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final List<String> categories = ['전체', '비', '바다', '바람', '불', '풀벌레', '도시'];

  final BannerAd _bannerAd = BannerAd(
    adUnitId: 'ca-app-pub-3940256099942544/6300978111',
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(),
  );

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _bannerAd.load();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteVideoUrls = prefs.getStringList('favorites') ?? [];
    });
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

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  Widget _buildCategoryButton(
      String label, bool isSelected, VoidCallback onPressed) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? Colors.blueAccent : Colors.blueGrey.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      ),
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
        child: Row(
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
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('에러 발생: \${snapshot.error}')),
          );
        }

        final videoDocs = snapshot.data?.docs ?? [];
        final allVideos = videoDocs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'title': data['title'] ?? '',
            'videoUrl': data['url'] ?? '',
            'thumbnail': data['thumbnail'] ?? '',
            'category':
                (data['category'] ?? '').toString().trim().toLowerCase(),
            'order': data['order'],
            'createdAt': data['createdAt']
          };
        }).toList();

        allVideos.sort((a, b) {
          final createdAtA = a['createdAt'];
          final createdAtB = b['createdAt'];
          if (createdAtA == null && createdAtB != null) return 1;
          if (createdAtA != null && createdAtB == null) return -1;
          if (createdAtA == null && createdAtB == null) return 0;
          return createdAtB.compareTo(createdAtA);
        });

        final baseFilteredVideos = selectedCategory == '전체'
            ? allVideos
            : allVideos
                .where((v) =>
                    v['category'] == selectedCategory.trim().toLowerCase())
                .toList();

        final filteredVideos = showFavoritesOnly
            ? baseFilteredVideos
                .where((v) => favoriteVideoUrls.contains(v['videoUrl']))
                .toList()
            : baseFilteredVideos;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: Row(
              children: [
                const Text(
                  '꿈꾸는고양이',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  'v1.0.1',
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
                            horizontal: 16, vertical: 8),
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
                child: isGrid
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          childAspectRatio: 16 / 14,
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
                      ),
              ),
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
