import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';

class EditGymInfoScreen extends StatefulWidget {
  final int gymId;

  const EditGymInfoScreen({super.key, required this.gymId});

  @override
  State<EditGymInfoScreen> createState() => _EditGymInfoScreenState();
}

class _EditGymInfoScreenState extends State<EditGymInfoScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  GymModel? _gym;

  // Form controllers
  late TextEditingController _gymNameController;
  late TextEditingController _gymSubNameController;
  late TextEditingController _locationNameController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _locationUrlController;
  late TextEditingController _categoryController;

  // Category options
  final List<String> _categories = [
    'GYM',
    'CROSSFIT',
    'YOGA',
    'PILATES',
    'BOXING',
    'MMA',
    'SPINNING',
    'SWIMMING',
    'TENNIS',
    'BASKETBALL',
    'CLIMBING',
    'DANCE',
    'MARTIAL ARTS',
    'PERSONAL TRAINING',
  ];
  String? _selectedCategory;

  // Day-wise operation hours
  final Map<String, DayHours> _dayHours = {};

  // Amenities
  final List<String> _selectedAmenities = [];
  final List<String> _availableAmenities = [
    'Free Weights',
    'Cardio Equipment',
    'Strength Training',
    'Personal Training',
    'Group Classes',
    'Yoga Studio',
    'Pilates',
    'Spinning/Cycling',
    'Swimming Pool',
    'Sauna',
    'Steam Room',
    'Jacuzzi/Hot Tub',
    'Tanning',
    'Locker Rooms',
    'Showers',
    'Towel Service',
    'Wi-Fi',
    'Parking',
    'Nutrition Shop',
    'Juice Bar',
    'Massage Therapy',
    'Physical Therapy',
    'Child Care',
    'Basketball Court',
    'Tennis Court',
    'Racquetball Court',
    'Climbing Wall',
    'Boxing Ring',
    'MMA Area',
    'CrossFit Area',
    'Functional Training',
    'Stretching Area',
    'Outdoor Training',
  ];

  // Images
  List<String> _imageUrls = [];
  List<String> _newImageBase64List = [];

  @override
  void initState() {
    super.initState();
    _gymNameController = TextEditingController();
    _gymSubNameController = TextEditingController();
    _locationNameController = TextEditingController();
    _contactPhoneController = TextEditingController();
    _locationUrlController = TextEditingController();
    _categoryController = TextEditingController();
    _initializeDayHours();
    _loadGymData();
  }

  void _initializeDayHours() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    for (final day in days) {
      _dayHours[day] = DayHours(isOpen: true, openTime: '6:00 AM', closeTime: '10:00 PM');
    }
  }

  @override
  void dispose() {
    _gymNameController.dispose();
    _gymSubNameController.dispose();
    _locationNameController.dispose();
    _contactPhoneController.dispose();
    _locationUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadGymData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gymProvider = context.read<GymProvider>();
      final gym = await gymProvider.fetchGymDetail(widget.gymId);
      
      if (gym != null) {
        setState(() {
          _gym = gym;
          _gymNameController.text = gym.name;
          _gymSubNameController.text = gym.subName;
          _locationNameController.text = gym.locationName;
          _contactPhoneController.text = gym.contactPhone;
          _imageUrls = List.from(gym.displayImages);
          _selectedAmenities.addAll(gym.amenities);
          _selectedCategory = gym.category;
          _parseOpenHours(gym.openHours);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load gym details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _parseOpenHours(String openHours) {
    // Parse format like "Mon-Fri: 6AM-10PM | Sat-Sun: 8AM-8PM"
    final parts = openHours.split(RegExp(r'\s*\|\s*'));
    
    for (final part in parts) {
      final match = RegExp(r'^(.+?):\s*(.+?)-(.+?)$').firstMatch(part);
      if (match != null) {
        final days = match.group(1)!;
        final openTime = match.group(2)!;
        final closeTime = match.group(3)!;
        
        // Handle day ranges like "Mon-Fri" or individual days
        if (days.contains('-')) {
          final dayRange = days.split('-');
          if (dayRange.length == 2) {
            final startIndex = _getDayIndex(dayRange[0].trim());
            final endIndex = _getDayIndex(dayRange[1].trim());
            if (startIndex != -1 && endIndex != -1) {
              for (int i = startIndex; i <= endIndex; i++) {
                final day = _getDayName(i);
                _dayHours[day] = DayHours(
                  isOpen: true,
                  openTime: _formatTime(openTime),
                  closeTime: _formatTime(closeTime),
                );
              }
            }
          }
        } else {
          // Single day
          final dayIndex = _getDayIndex(days.trim());
          if (dayIndex != -1) {
            final day = _getDayName(dayIndex);
            _dayHours[day] = DayHours(
              isOpen: true,
              openTime: _formatTime(openTime),
              closeTime: _formatTime(closeTime),
            );
          }
        }
      }
    }
  }

  int _getDayIndex(String day) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days.indexOf(day);
  }

  String _getDayName(int index) {
    if (index < 7) {
      final shortDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return shortDays[index];
    }
    return '';
  }

  String _formatTime(String time) {
    // Convert "6AM" to "6:00 AM" format
    final match = RegExp(r'(\d+)(?::(\d+))?\s*(AM|PM)', caseSensitive: false).firstMatch(time);
    if (match != null) {
      final hour = match.group(1)!;
      final minute = match.group(2) ?? '00';
      final period = match.group(3)!.toUpperCase();
      return '$hour:$minute $period';
    }
    return time;
  }

  String _formatOpenHours() {
    // Format day hours back to string like "Mon-Fri: 6:00 AM-10:00 PM | Sat-Sun: 8:00 AM-8:00 PM"
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> parts = [];
    
    int i = 0;
    while (i < days.length) {
      final day = days[i];
      final hours = _dayHours[day];
      
      if (hours != null && hours.isOpen) {
        // Find consecutive days with same hours
        int j = i + 1;
        while (j < days.length) {
          final nextHours = _dayHours[days[j]];
          if (nextHours == null || !nextHours.isOpen || 
              nextHours.openTime != hours.openTime || 
              nextHours.closeTime != hours.closeTime) {
            break;
          }
          j++;
        }
        
        // Format day range
        String dayRange;
        if (j == i + 1) {
          dayRange = _getShortDayName(i);
        } else {
          dayRange = '${_getShortDayName(i)}-${_getShortDayName(j - 1)}';
        }
        
        parts.add('$dayRange: ${hours.openTime}-${hours.closeTime}');
        i = j;
      } else {
        i++;
      }
    }
    
    return parts.join(' | ');
  }

  String _getShortDayName(int index) {
    final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return shortDays[index];
  }

  Future<Map<String, double>?> _parseLocationUrl(String url) async {
    try {
      // Call backend to parse location URL
      final gymProvider = context.read<GymProvider>();
      final response = await gymProvider.parseLocationUrl(url);
      if (response != null) {
        return {
          'latitude': response['latitude'] as double,
          'longitude': response['longitude'] as double,
        };
      }
    } catch (e) {
      print('Error parsing location URL: $e');
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;
      
      final bytes = await picked.readAsBytes();
      final b64 = base64Encode(bytes);
      
      setState(() {
        _newImageBase64List.add(b64);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _removeImage(int index, bool isNew) {
    setState(() {
      if (isNew) {
        _newImageBase64List.removeAt(index);
      } else {
        _imageUrls.removeAt(index);
      }
    });
  }

  Future<void> _saveGymInfo() async {
    if (_gymNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gym name cannot be empty'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final gymProvider = context.read<GymProvider>();
      
      // Combine existing images with new ones
      final allImages = [..._imageUrls, ..._newImageBase64List];
      
      // Format open hours from day-wise data
      final formattedOpenHours = _formatOpenHours();
      
      // Parse location URL if provided
      double? newLatitude;
      double? newLongitude;
      if (_locationUrlController.text.trim().isNotEmpty) {
        final locationData = await _parseLocationUrl(_locationUrlController.text.trim());
        if (locationData != null) {
          newLatitude = locationData['latitude'];
          newLongitude = locationData['longitude'];
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  gymProvider.errorMessage ?? 'Invalid Google Maps URL. Please check your link.',
                ),
                backgroundColor: Colors.redAccent,
              ),
            );
            setState(() {
              _isSaving = false;
            });
          }
          return;
        }
      }
      
      final success = await gymProvider.updateGymDetails(
        gymId: widget.gymId,
        gymName: _gymNameController.text.trim(),
        gymSubName: _gymSubNameController.text.trim().isNotEmpty 
            ? _gymSubNameController.text.trim() 
            : null,
        locationName: _locationNameController.text.trim().isNotEmpty 
            ? _locationNameController.text.trim() 
            : null,
        contactPhone: _contactPhoneController.text.trim().isNotEmpty 
            ? _contactPhoneController.text.trim() 
            : null,
        category: _selectedCategory,
        openHours: formattedOpenHours.isNotEmpty ? formattedOpenHours : null,
        images: allImages.isNotEmpty ? allImages : null,
        amenities: _selectedAmenities.isNotEmpty ? _selectedAmenities : null,
        latitude: newLatitude,
        longitude: newLongitude,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.black, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Gym info updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                gymProvider.errorMessage ?? 'Failed to update gym info',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 28),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'EDIT GYM INFO',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveGymInfo,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadGymData,
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Gym Name
                      _buildEditField(
                        controller: _gymNameController,
                        label: 'Gym Name',
                        hint: 'Enter gym name',
                      ),
                      const SizedBox(height: 20),

                      // Gym Sub Name
                      _buildEditField(
                        controller: _gymSubNameController,
                        label: 'Gym Sub Name',
                        hint: 'Enter gym sub name (optional)',
                      ),
                      const SizedBox(height: 20),

                      // Location Name
                      _buildEditField(
                        controller: _locationNameController,
                        label: 'Location Name',
                        hint: 'Enter location name',
                      ),
                      const SizedBox(height: 20),

                      // Category
                      _buildCategoryDropdown(),
                      const SizedBox(height: 20),

                      // Location URL (for updating coordinates)
                      _buildEditField(
                        controller: _locationUrlController,
                        label: 'Location URL (Google Maps)',
                        hint: 'Paste Google Maps URL to update coordinates',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),

                      // Contact Phone
                      _buildEditField(
                        controller: _contactPhoneController,
                        label: 'Contact Phone',
                        hint: 'Enter contact phone number',
                        isNumber: true,
                      ),
                      const SizedBox(height: 20),

                      // Operation Hours - Day Wise
                      _buildOperationHoursSection(),
                      const SizedBox(height: 24),

                      // Amenities Section
                      _buildAmenitiesSection(),
                      const SizedBox(height: 24),

                      // Images Section
                      _buildImagesSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gym Images',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 20),
              label: const Text(
                'Add Image',
                style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_imageUrls.isEmpty && _newImageBase64List.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.image_outlined, color: Colors.white24, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'No images added',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: _imageUrls.length + _newImageBase64List.length,
            itemBuilder: (context, index) {
              final isNew = index >= _imageUrls.length;
              final newIndex = isNew ? index - _imageUrls.length : index;
              final imageUrl = isNew ? null : _imageUrls[index];
              
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImageWidget(isNew, imageUrl, newIndex),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index, isNew),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              hint: const Text(
                'Select category',
                style: TextStyle(color: Colors.white24, fontSize: 15),
              ),
              isExpanded: true,
              dropdownColor: const Color(0xFF1E1E1E),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperationHoursSection() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operation Hours',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: days.map((day) {
              final hours = _dayHours[day];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Day name
                    SizedBox(
                      width: 80,
                      child: Text(
                        day.substring(0, 3),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Open/Closed toggle
                    Switch(
                      value: hours?.isOpen ?? true,
                      onChanged: (value) {
                        setState(() {
                          _dayHours[day] = DayHours(
                            isOpen: value,
                            openTime: hours?.openTime ?? '6:00 AM',
                            closeTime: hours?.closeTime ?? '10:00 PM',
                          );
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    // Open time
                    Expanded(
                      child: InkWell(
                        onTap: hours?.isOpen == true ? () => _selectTime(day, true) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: hours?.isOpen == true ? const Color(0xFF2A2A2A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hours?.isOpen == true ? hours!.openTime : 'Closed',
                            style: TextStyle(
                              color: hours?.isOpen == true ? Colors.white : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('-', style: TextStyle(color: Colors.white38)),
                    const SizedBox(width: 8),
                    // Close time
                    Expanded(
                      child: InkWell(
                        onTap: hours?.isOpen == true ? () => _selectTime(day, false) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: hours?.isOpen == true ? const Color(0xFF2A2A2A) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hours?.isOpen == true ? hours!.closeTime : 'Closed',
                            style: TextStyle(
                              color: hours?.isOpen == true ? Colors.white : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _selectTime(String day, bool isOpenTime) async {
    final hours = _dayHours[day];
    if (hours == null) return;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(isOpenTime ? hours.openTime : hours.closeTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final formattedTime = _formatTimeOfDay(picked);
        _dayHours[day] = DayHours(
          isOpen: hours.isOpen,
          openTime: isOpenTime ? formattedTime : hours.openTime,
          closeTime: !isOpenTime ? formattedTime : hours.closeTime,
        );
      });
    }
  }

  TimeOfDay _parseTime(String time) {
    final match = RegExp(r'(\d+):(\d+)\s*(AM|PM)', caseSensitive: false).firstMatch(time);
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final period = match.group(3)!.toUpperCase();
      
      if (period == 'PM' && hour != 12) {
        return TimeOfDay(hour: hour + 12, minute: minute);
      } else if (period == 'AM' && hour == 12) {
        return TimeOfDay(hour: 0, minute: minute);
      }
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 6, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableAmenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(
                  amenity,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFF2A2A2A),
                checkmarkColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.white10,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageWidget(bool isNew, String? imageUrl, int newIndex) {
    if (isNew) {
      // New image from gallery (base64)
      try {
        final base64String = _newImageBase64List[newIndex];
        final paddedBase64 = _padBase64(base64String);
        return Image.memory(
          base64Decode(paddedBase64),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1E1E1E),
            child: const Icon(Icons.broken_image, color: Colors.white24),
          ),
        );
      } catch (e) {
        print('Error decoding new base64 image: $e');
        return Container(
          color: const Color(0xFF1E1E1E),
          child: const Icon(Icons.broken_image, color: Colors.white24),
        );
      }
    } else {
      // Existing image from database
      if (imageUrl == null || imageUrl.isEmpty) {
        return Container(
          color: const Color(0xFF1E1E1E),
          child: const Icon(Icons.broken_image, color: Colors.white24),
        );
      }
      
      // Check if it's a base64 string
      if (imageUrl.startsWith('data:')) {
        // Full data URI with prefix
        try {
          final base64Part = imageUrl.split(',').last;
          final paddedBase64 = _padBase64(base64Part);
          return Image.memory(
            base64Decode(paddedBase64),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1E1E1E),
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          );
        } catch (e) {
          print('Error decoding base64 image with data URI: $e');
          return Container(
            color: const Color(0xFF1E1E1E),
            child: const Icon(Icons.broken_image, color: Colors.white24),
          );
        }
      } else if (imageUrl.startsWith('/9j/') || imageUrl.startsWith('iVBORw')) {
        // Base64 without prefix - assume JPEG or PNG
        try {
          final paddedBase64 = _padBase64(imageUrl);
          return Image.memory(
            base64Decode(paddedBase64),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1E1E1E),
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),
          );
        } catch (e) {
          print('Error decoding base64 image: $e');
          return Container(
            color: const Color(0xFF1E1E1E),
            child: const Icon(Icons.broken_image, color: Colors.white24),
          );
        }
      } else {
        // Regular URL
        return Image.network(
          imageUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: const Color(0xFF1E1E1E),
            child: const Icon(Icons.broken_image, color: Colors.white24),
          ),
        );
      }
    }
  }

  String _padBase64(String base64) {
    // Remove any whitespace
    base64 = base64.replaceAll(RegExp(r'\s'), '');
    
    // Add padding if needed (base64 must be multiple of 4)
    while (base64.length % 4 != 0) {
      base64 += '=';
    }
    return base64;
  }
}

class DayHours {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  DayHours({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });
}
