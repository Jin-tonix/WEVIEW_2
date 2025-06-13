import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../setting/settingscreen.dart';
import 'communitypost.dart';
import 'communityscreen.dart';
import '../hospital/hospital_search_screen.dart';
import 'review_write_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  final List<Widget> _pages = [
    CommunityScreen(),
    CategoryGridScreen(),
    MyPageScreen(),
  ];

  @override
  void initState() {
    super.initState();
    requestLocationPermission();
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("Location permission granted");
    } else {
      print("Location permission denied");
      if (status.isPermanentlyDenied) {
        openAppSettings(); // 권한 설정 화면으로 유도
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openSetting() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingScreen()),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    switch (_selectedIndex) {
      case 0:
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityPost()),
            );
          },
          backgroundColor: Colors.indigo,
          tooltip: 'Write Post',
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 1:
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReviewWriteScreen()),
            );
          },
          backgroundColor: Colors.indigo,
          tooltip: 'Write Review',
          child: const Icon(Icons.add, color: Colors.white),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'WEVIEW',
          style: TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.indigo),
            onPressed: _openSetting,
          ),
        ],
        foregroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }
}

// ------ Pages ------

class CategoryGridScreen extends StatefulWidget {
  const CategoryGridScreen({super.key});

  @override
  State<CategoryGridScreen> createState() => _CategoryGridScreenState();
}

class _CategoryGridScreenState extends State<CategoryGridScreen> {
  final TextEditingController _searchController = TextEditingController();

  final categories = const [
    {'label': 'Hospital', 'icon': Icons.local_hospital},
    {'label': 'Restaurant', 'icon': Icons.restaurant},
    {'label': 'Cafe', 'icon': Icons.local_cafe},
    {'label': 'Tourist Spot', 'icon': Icons.location_on},
    {'label': 'Cultural Facility', 'icon': Icons.museum},
    {'label': 'Accommodation', 'icon': Icons.hotel},
  ];

  void _onSearch(String keyword) {
    if (keyword.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HospitalSearchScreen(initialKeyword: keyword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _onSearch,
                  decoration: InputDecoration(
                    hintText: 'Enter a keyword to search',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _onSearch(_searchController.text),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: categories.sublist(0, 2).map((category) {
                      return Expanded(child: CategoryItem(category: category));
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: categories.sublist(2, 4).map((category) {
                      return Expanded(child: CategoryItem(category: category));
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Row(
                    children: categories.sublist(4, 6).map((category) {
                      return Expanded(child: CategoryItem(category: category));
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final Map category;
  const CategoryItem({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HospitalSearchScreen(
                initialKeyword: category['label'],
              ),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(category['icon'], size: 40), // 아이콘 수정
              const SizedBox(height: 8),
              Text(
                category['label'],
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('My Page'));
  }
}
