import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_webservice/places.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String? initialPlaceId;
  final String? initialHospitalName;

  const ReviewWriteScreen({super.key, this.initialPlaceId, this.initialHospitalName});

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hospitalNameController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  String _selectedDepartment = 'Internal Medicine';
  String? _selectedSubCategory;
  double _rating = 3.0;
  List<XFile>? _pickedImages;
  List<Prediction> _predictions = [];
  String? _selectedPlaceId;

  late GoogleMapsPlaces _places;

  final departments = [
    'Internal Medicine', 'ENT', 'Orthopedics', 'Dermatology', 'Plastic Surgery',
  ];

  final plasticSurgerySubCategories = [
    'Eyes', 'Nose', 'Mouth', 'Facelift', 'Jaw Surgery', 'Liposuction', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GOOGLE_PLACES_ANDROID_API_KEY'];
    assert(apiKey != null && apiKey.isNotEmpty, 'Google Places API Key is required!');
    _places = GoogleMapsPlaces(apiKey: apiKey!);

    if (widget.initialHospitalName != null) {
      _hospitalNameController.text = widget.initialHospitalName!;
    }
    if (widget.initialPlaceId != null) {
      _selectedPlaceId = widget.initialPlaceId!;
    }
  }

  Future<void> _searchHospital() async {
    final keyword = _hospitalNameController.text.trim();
    if (keyword.isEmpty) return;

    try {
      final result = await _places.autocomplete(
        keyword,
        components: [Component(Component.country, 'kr')],
        radius: 30000,
      );

      if (!mounted) return;
      setState(() => _predictions = result.isOkay ? result.predictions : []);
      if (!result.isOkay) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? '검색 결과가 없습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검색에 실패했습니다: $e')),
      );
    }
  }

  Future<void> _selectHospital(Prediction p) async {
    final placeId = p.placeId;
    final name = p.description;

    if (placeId != null && name != null) {
      if (!mounted) return;
      setState(() {
        _hospitalNameController.text = name;
        _selectedPlaceId = placeId;
        _predictions = [];
      });

      final docRef = FirebaseFirestore.instance.collection('hospitals').doc(placeId);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({'name': name, 'createdAt': Timestamp.now()});
      }
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (!mounted) return;
    if (images.isNotEmpty) setState(() => _pickedImages = images);
  }

  // 이미지 취소 기능
  void _removeImage(XFile image) {
    setState(() {
      _pickedImages?.remove(image);
    });
  }

  Future<List<String>> _uploadImages() async {
    List<String> urls = [];
    for (final image in _pickedImages!) {
      // 고유 경로 생성
      final filePath = 'review_images/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      print("업로드될 파일 경로: $filePath"); // 파일 경로 확인용

      final ref = FirebaseStorage.instance.ref(filePath);

      try {
        // 이미지 업로드
        await ref.putFile(File(image.path));

        // 업로드 후 다운로드 URL 얻기
        final downloadUrl = await ref.getDownloadURL();
        urls.add(downloadUrl);  // 다운로드 URL 리스트에 추가
      } catch (e) {
        print("❌ 이미지 업로드 실패: $e");
        throw Exception("이미지 업로드 실패");  // 업로드 실패 시 예외 발생
      }
    }
    return urls;  // 업로드된 이미지들의 다운로드 URL을 반환
  }


  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    final placeId = _selectedPlaceId;
    final name = _hospitalNameController.text.trim();

    if (placeId == null || name.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please search and select a hospital')),
      );
      return;
    }

    List<String> imageUrls = [];
    try {
      if (_pickedImages != null && _pickedImages!.isNotEmpty) {
        imageUrls = await _uploadImages();  // 이미지 업로드
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),  // 이미지 업로드 실패 시 에러 메시지
      );
      return;
    }

    final reviewData = {
      'placeId': placeId,
      'hospitalName': name,
      'department': _selectedDepartment,
      'subCategory': _selectedDepartment == 'Plastic Surgery' ? _selectedSubCategory : null,
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'images': imageUrls,
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance.collection('reviews').add(reviewData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlastic = _selectedDepartment == 'Plastic Surgery';

    return Scaffold(
      appBar: AppBar(title: const Text('Write Hospital Review')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Hospital Name'),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hospitalNameController,
                      validator: (value) => value!.isEmpty ? 'Please enter hospital name' : null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchHospital,
                  )
                ],
              ),
              if (_predictions.isNotEmpty)
                ..._predictions.map((p) => ListTile(
                  title: Text(p.description ?? ''),
                  onTap: () => _selectHospital(p),
                )),
              const SizedBox(height: 12),
              const Text('Select Department'),
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                items: departments.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value!;
                    _selectedSubCategory = null;
                  });
                },
              ),
              if (isPlastic) ...[
                const SizedBox(height: 12),
                const Text('Select Plastic Surgery Type'),
                DropdownButtonFormField<String>(
                  value: _selectedSubCategory,
                  items: plasticSurgerySubCategories
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedSubCategory = value),
                  validator: (value) => value == null ? 'Please select a type' : null,
                ),
              ],
              const SizedBox(height: 12),
              const Text('Rating'),
              Slider(
                value: _rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toString(),
                onChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 12),
              const Text('Your Review'),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Please write your review' : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.image),
                label: const Text('Add Photos'),
              ),
              const SizedBox(height: 8),
              if (_pickedImages != null)
                Wrap(
                  spacing: 8,
                  children: _pickedImages!
                      .map((img) => Stack(
                    children: [
                      Image.file(File(img.path), width: 60, height: 60, fit: BoxFit.cover),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.red),
                          onPressed: () => _removeImage(img),
                        ),
                      ),
                    ],
                  ))
                      .toList(),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text('Submit Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
