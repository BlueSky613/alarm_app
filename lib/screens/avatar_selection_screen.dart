import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Simple avatar selection screen inspired by the SolRise HTML reference.
class AvatarSelectionScreen extends StatefulWidget {
  const AvatarSelectionScreen({super.key, this.initialAvatarRef});

  /// `default` | `asset:assets/avatar/...` | `file:<path>`
  final String? initialAvatarRef;

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  // Avatars sourced from assets/avatar/*. Ensure these files exist.
  final List<String> _avatarAssets = const [
    'assets/avatar/man_1.webp',
    'assets/avatar/man_2.webp',
    'assets/avatar/man_3.webp',
    'assets/avatar/man_4.webp',
    'assets/avatar/man_5.webp',
    'assets/avatar/man_6.webp',
    'assets/avatar/woman_1.webp',
    'assets/avatar/woman_2.webp',
    'assets/avatar/woman_3.webp',
    'assets/avatar/woman_4.webp',
    'assets/avatar/woman_5.webp',
    'assets/avatar/woman_6.webp',
    'assets/avatar/man_7.webp',
    'assets/avatar/man_8.webp',
    'assets/avatar/man_9.webp',
    'assets/avatar/man_10.webp',
    'assets/avatar/man_11.webp',
    'assets/avatar/woman_7.webp',
    'assets/avatar/woman_8.webp',
    'assets/avatar/woman_9.webp',
    'assets/avatar/woman_10.webp',
    'assets/avatar/woman_11.webp',
    'assets/avatar/woman_12.webp',
    'assets/avatar/woman_13.webp',
    'assets/avatar/woman_14.webp',
    'assets/avatar/woman_15.webp',
    'assets/avatar/woman_18.webp',
    'assets/avatar/woman_19.webp',
    'assets/avatar/woman_20.webp',
    'assets/avatar/woman_21.webp',
  ];

  final ImagePicker _picker = ImagePicker();

  late int _selectedIndex;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _pickedImageFile = null;
    final ref = widget.initialAvatarRef?.trim() ?? '';
    if (ref.isNotEmpty && ref != 'default') {
      if (ref.startsWith('file:')) {
        final path = ref.substring(5);
        final f = File(path);
        if (f.existsSync()) _pickedImageFile = f;
      } else if (ref.startsWith('asset:')) {
        final path = ref.substring(6);
        final idx = _avatarAssets.indexOf(path);
        if (idx >= 0) _selectedIndex = idx;
      } else if (_avatarAssets.contains(ref)) {
        _selectedIndex = _avatarAssets.indexOf(ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Change Avatar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop<String>(_serializeAvatarRef());
                    },
                    child: Text(
                      'CONFIRM',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color.fromRGBO(14, 241, 150, 0.8),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentAvatar(theme),
                    const SizedBox(height: 24),
                    _buildUploadButton(theme),
                    const SizedBox(height: 24),
                    _buildAvatarGrid(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAvatar(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromRGBO(14, 241, 150, 0.2),
                    ),
                  ),
                ),
              ),
              Container(
                width: 136,
                height: 136,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(14, 241, 150, 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: ClipOval(
                  child: Image(image: _currentImageProvider, fit: BoxFit.cover),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: _onTakePhoto,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.35),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromRGBO(14, 241, 150, 0.2),
                          border: Border.all(
                            color: const Color.fromRGBO(14, 241, 150, 0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          color: Color.fromRGBO(14, 241, 150, 1),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap an avatar below to change',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUploadButton(ThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: const Color.fromRGBO(14, 241, 150, 0.2)),
          ),
          child: TextButton.icon(
            onPressed: _onUploadFromGallery,
            icon: const Icon(
              Icons.cloud_upload_outlined,
              color: Color.fromRGBO(14, 241, 150, 1),
            ),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Upload from Gallery',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Choose a SolRise Avatar',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _avatarAssets.length,
          itemBuilder: (context, index) {
            final asset = _avatarAssets[index];
            final isSelected = index == _selectedIndex;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                  _pickedImageFile = null;
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withOpacity(0.04),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromRGBO(14, 241, 150, 1)
                            : Colors.white.withOpacity(0.12),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(asset, fit: BoxFit.cover),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color.fromRGBO(14, 241, 150, 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(
                                      14,
                                      241,
                                      150,
                                      1,
                                    ).withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  ImageProvider get _currentImageProvider {
    if (_pickedImageFile != null) {
      return FileImage(_pickedImageFile!);
    }
    return AssetImage(_avatarAssets[_selectedIndex]);
  }

  String _serializeAvatarRef() {
    if (_pickedImageFile != null) {
      return 'file:${_pickedImageFile!.path}';
    }
    return 'asset:${_avatarAssets[_selectedIndex]}';
  }

  Future<void> _onUploadFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (file == null) return;
    setState(() {
      _pickedImageFile = File(file.path);
    });
  }

  Future<void> _onTakePhoto() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (file == null) return;
    setState(() {
      _pickedImageFile = File(file.path);
    });
  }
}
