import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/api_service.dart';

class ImageGeneratorScreen extends StatefulWidget {
  const ImageGeneratorScreen({super.key});

  @override
  State<ImageGeneratorScreen> createState() => _ImageGeneratorScreenState();
}

class _ImageGeneratorScreenState extends State<ImageGeneratorScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _promptController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey();
  final Random _random = Random();
  Uint8List? _imageBytes;
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _randomPrompts = [
    'A cyberpunk cityscape at night with neon lights',
    'A majestic dragon flying over medieval castle',
    'An astronaut riding a horse in photorealistic style',
    'A futuristic underwater city with glass domes',
    'A cute corgi puppy wearing sunglasses on a beach',
    'A steampunk airship flying through clouds',
    'A magical forest with glowing plants and fairies',
    'A robot chef cooking in a high-tech kitchen',
    'A samurai cat wearing armor in cherry blossom forest',
    'A surreal landscape with floating islands',
    'A hockey player using a watermelon as a puck',
    '3 bears arguing over a pot of honey',
    'A steampunk warrior battling a cloud of steam',
  ];

  Future<void> _generateImage([String? prompt]) async {
    final effectivePrompt = prompt ?? _promptController.text;
    if (effectivePrompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _imageBytes = null;
      _errorMessage = null;
    });

    try {
      final bytes = await _apiService.generateImage(effectivePrompt);
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      setState(() => _errorMessage = errorMessage);
      _handleApiError(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleRandomPrompt() {
    final randomPrompt = _randomPrompts[_random.nextInt(_randomPrompts.length)];
    _promptController.text = randomPrompt;
    _generateImage(randomPrompt);
  }

  void _handleApiError(String errorMessage) {
    if (!mounted) return;
    final messenger = _scaffoldMessengerKey.currentState!;
    messenger.clearSnackBars();

    if (errorMessage.contains('Model is loading')) {
      final seconds = RegExp(r'\d+').firstMatch(errorMessage)?.group(0) ?? '30';
      messenger.showSnackBar(
        SnackBar(
          content: Text('Model initializing... Auto-retry in $seconds seconds'),
          duration: Duration(seconds: int.parse(seconds)),
        ),
      );

      Future.delayed(Duration(seconds: int.parse(seconds))).then((_) {
        if (mounted) _generateImage();
      });
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI Image Generator'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shuffle),
              onPressed: _isLoading ? null : _handleRandomPrompt,
              tooltip: 'Random Prompt',
            ),
            if (_imageBytes != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _generateImage,
                tooltip: 'Regenerate',
              ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe your imagination...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.auto_awesome, color: Colors.blue[200]),
                      onPressed: _isLoading ? null : _handleRandomPrompt,
                    ),
                  ),
                  maxLines: 3,
                  onSubmitted: (_) => _generateImage(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _isLoading
                        ? SpinKitThreeBounce(color: Colors.white, size: 20)
                        : const Icon(Icons.generating_tokens_outlined),
                    label: Text(
                      _isLoading ? 'Creating Magic...' : 'Generate Image',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _isLoading ? null : () => _generateImage(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(child: _buildImagePreview()),
                if (!_isLoading && _imageBytes == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      'Tip: Try "A futuristic city under northern lights"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitFadingCircle(color: Colors.blue[400], size: 50),
            const SizedBox(height: 15),
            const Text(
              'Painting your vision...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_imageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InteractiveViewer(
          minScale: 0.1,
          maxScale: 4.0,
          child: Image.memory(_imageBytes!, fit: BoxFit.contain),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.red[300]),
              const SizedBox(height: 20),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[300], fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 50, color: Colors.blue[200]),
          const SizedBox(height: 20),
          const Text(
            'Your AI-generated masterpiece\nawaits...',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
