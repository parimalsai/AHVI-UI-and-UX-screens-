import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/profile.dart';
import 'package:myapp/theme/theme_tokens.dart';
import 'package:permission_handler/permission_handler.dart';

enum LensEntryAction {
  findSimilar,
  addToWardrobe,
  askAhvi,
}

extension LensEntryActionText on LensEntryAction {
  String get title => switch (this) {
        LensEntryAction.findSimilar => 'Find Similar',
        LensEntryAction.addToWardrobe => 'Add to Wardrobe',
        LensEntryAction.askAhvi => 'Ask AHVI',
      };

  String get hint => switch (this) {
        LensEntryAction.findSimilar => 'Point at an item to find similar looks',
        LensEntryAction.addToWardrobe => 'Capture a piece to save it to your closet',
        LensEntryAction.askAhvi => 'Capture and ask for style advice instantly',
      };
}

class LensCameraPage extends StatefulWidget {
  final LensEntryAction action;

  const LensCameraPage({
    super.key,
    required this.action,
  });

  @override
  State<LensCameraPage> createState() => _LensCameraPageState();
}

class _LensCameraPageState extends State<LensCameraPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isPermissionDenied = false;
  bool _isPermissionPermanentlyDenied = false;
  String? _errorMessage;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );
    _initializeCameraFlow();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCameraFlow({bool forcePrompt = false}) async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _isPermissionDenied = false;
      _isPermissionPermanentlyDenied = false;
      _errorMessage = null;
    });

    try {
      final granted = await _ensureCameraPermission(forcePrompt: forcePrompt);
      if (!granted || !mounted) {
        setState(() => _isInitializing = false);
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera available on this device.';
        });
        return;
      }

      final selected = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final old = _controller;
      _controller = controller;
      await old?.dispose();

      setState(() => _isInitializing = false);
    } on CameraException catch (e) {
      if (!mounted) return;
      final deniedCode = e.code.toLowerCase();
      final accessDenied = deniedCode.contains('accessdenied');
      setState(() {
        _isInitializing = false;
        _isPermissionDenied = accessDenied;
        _errorMessage = accessDenied
            ? 'Camera permission is required to use Lens.'
            : 'Could not start camera (${e.code}).';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Camera failed to initialize. Please try again.';
      });
    }
  }

  Future<bool> _ensureCameraPermission({required bool forcePrompt}) async {
    var status = await Permission.camera.status;
    if (status.isGranted) return true;

    if (forcePrompt || status.isDenied || status.isRestricted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) return true;

    if (!mounted) return false;
    setState(() {
      _isPermissionDenied = true;
      _isPermissionPermanentlyDenied = status.isPermanentlyDenied;
      _errorMessage = status.isPermanentlyDenied
          ? 'Camera permission is permanently denied.'
          : 'Camera permission denied.';
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.themeTokens;
    final lensTheme = ProfileLensCameraTheme.fromTokens(t);
    final cameraReady = _controller?.value.isInitialized ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (cameraReady)
            CameraPreview(_controller!)
          else
            Container(color: Colors.black),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lensTheme.scrim,
                    Colors.transparent,
                    lensTheme.scrim,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _buildTopBar(lensTheme),
                  const Spacer(),
                  _buildScanOverlay(lensTheme),
                  const Spacer(),
                  _buildBottomPanel(lensTheme),
                ],
              ),
            ),
          ),
          if (_isInitializing || !cameraReady) _buildLoadingLayer(lensTheme),
          if (_isPermissionDenied || _errorMessage != null)
            _buildFailureLayer(lensTheme),
        ],
      ),
    );
  }

  Widget _buildTopBar(ProfileLensCameraTheme lensTheme) {
    return Row(
      children: [
        _GlassButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).maybePop(),
          color: lensTheme.primaryAction,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.action.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lensTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 56),
      ],
    );
  }

  Widget _buildScanOverlay(ProfileLensCameraTheme lensTheme) {
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: lensTheme.frameBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: lensTheme.frameGlow,
              blurRadius: 16,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'Align item',
            style: TextStyle(
              color: lensTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(ProfileLensCameraTheme lensTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: lensTheme.controlPanel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: lensTheme.chipBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.action.hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: lensTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lensTheme.primaryAction, lensTheme.secondaryAction],
              ),
              boxShadow: [
                BoxShadow(
                  color: lensTheme.primaryAction.withValues(alpha: 0.45),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                size: 24, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingLayer(ProfileLensCameraTheme lensTheme) {
    return IgnorePointer(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2.6,
                color: lensTheme.primaryAction,
              ),
              const SizedBox(height: 12),
              Text(
                'Opening camera…',
                style: TextStyle(
                  color: lensTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFailureLayer(ProfileLensCameraTheme lensTheme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: lensTheme.controlPanel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: lensTheme.chipBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt_rounded,
                  color: lensTheme.primaryAction, size: 30),
              const SizedBox(height: 10),
              Text(
                _errorMessage ?? 'Unable to open camera.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: lensTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _initializeCameraFlow(forcePrompt: true),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: lensTheme.chipBorder),
                      ),
                      child: const Text('Retry'),
                    ),
                  ),
                  if (_isPermissionPermanentlyDenied) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: openAppSettings,
                        child: const Text('Settings'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _GlassButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.36)),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}
