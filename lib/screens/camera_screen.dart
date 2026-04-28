import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  List<CameraDescription> _cameras = [];
  int _selectedCamera = 0; 
  bool _isTaking = false;
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    await _setupController(_selectedCamera);
  }

  Future<void> _setupController(int index) async {
    await _controller?.dispose();
    final controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    _initFuture = controller.initialize();
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCamera = _selectedCamera == 0 ? 1 : 0;
    await _setupController(_selectedCamera);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || _isTaking) return;
    setState(() => _isTaking = true);
    try {
      await _initFuture;
      final image = await _controller!.takePicture();
      await Gal.putImage(image.path, album: 'PrivacyAudit');
      setState(() {
        _previewFile = File(image.path);
        _isTaking = false;
      });
    } catch (e) {
      setState(() => _isTaking = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')));
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      Navigator.pop(context, File(file.path));
    }
  }

  Future<void> _pickScreenshot() async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to screenshot app permissions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _screenshotStep('1', 'Open phone  Settings → Apps'),
            _screenshotStep('2', 'Tap the app you want to audit'),
            _screenshotStep('3', 'Tap Permissions'),
            _screenshotStep('4',
                'Take a screenshot (Power + Volume Down)'),
            _screenshotStep('5', 'Come back here and tap the button below'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  _pickFromGallery();
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick Screenshot from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _screenshotStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF185FA5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    if (_previewFile != null) {
      Navigator.pop(context, _previewFile);
    }
  }

  void _retake() {
    setState(() => _previewFile = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Add evidence photo'),
        actions: [
          TextButton.icon(
            onPressed: _pickScreenshot,
            icon: const Icon(Icons.screenshot_monitor,
                color: Colors.white, size: 20),
            label: const Text('Screenshot',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
          TextButton.icon(
            onPressed: _pickFromGallery,
            icon: const Icon(Icons.photo_library_outlined,
                color: Colors.white, size: 20),
            label: const Text('Gallery',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: _previewFile != null
          ? Column(
              children: [
                Expanded(
                  child: Image.file(
                    _previewFile!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _retake,
                          icon: const Icon(Icons.refresh,
                              color: Colors.white),
                          label: const Text('Retake',
                              style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check),
                          label: const Text('Use photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF185FA5),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _initFuture == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : FutureBuilder<void>(
                  future: _initFuture,
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.done) {
                      return Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          SizedBox.expand(
                            child: CameraPreview(_controller!),
                          ),

                          Positioned(
                            top: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Point at your phone settings screen',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),

                          if (_cameras.length > 1)
                            Positioned(
                              top: 12,
                              right: 16,
                              child: GestureDetector(
                                onTap: _switchCamera,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.flip_camera_android,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 40),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: _pickFromGallery,
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.photo_library_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),

                                GestureDetector(
                                  onTap:
                                      _isTaking ? null : _takePicture,
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 3),
                                      color: _isTaking
                                          ? Colors.grey
                                          : Colors.white.withOpacity(0.3),
                                    ),
                                    child: _isTaking
                                        ? const Center(
                                            child:
                                                CircularProgressIndicator(
                                                    color: Colors.white))
                                        : const Icon(Icons.camera_alt,
                                            color: Colors.white, size: 34),
                                  ),
                                ),

                                GestureDetector(
                                  onTap: _pickScreenshot,
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.screenshot_monitor,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white));
                  },
                ),
    );
  }
}
