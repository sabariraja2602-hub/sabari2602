// lib/audio_call_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'call_manager.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:html'
    as html
    show AudioElement, document; // Only for web audio fix

class AudioCallPage extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;
  final bool isCaller;
  final bool isVideo;
  final Map? offerSignal;

  const AudioCallPage({
    super.key,
    required this.currentUserId,
    required this.targetUserId,
    this.isCaller = false,
    this.isVideo = false,
    this.offerSignal,
  });

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  late CallManager _callManager;
  final _remoteRenderer = RTCVideoRenderer();
  final _localRenderer = RTCVideoRenderer();

  bool _connected = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  // ✅ Added for improved web audio handling
  html.AudioElement? _webAudioElement;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
    _setupCallManager();
  }

  Future<void> _initializeRenderers() async {
    await _remoteRenderer.initialize();
    await _localRenderer.initialize();
  }

  void _setupCallManager() {
    _callManager = CallManager(
      serverUrl: 'https://sabari2602.onrender.com',
      currentUserId: widget.currentUserId,
    );

    // 🎧 Local preview
    _callManager.onLocalStream = (MediaStream? stream) async {
      if (stream == null) return;

      if (_localRenderer.textureId == null) {
        await _initializeRenderers();
      }

      if (widget.isVideo) {
        setState(() => _localRenderer.srcObject = stream);
      }
    };

    // 🎧 Remote stream
    _callManager.onRemoteStream = (MediaStream? stream) async {
      if (stream == null) return;

      setState(() {
        _remoteRenderer.srcObject = stream;
        _connected = true;
      });

      try {
        // Enable all audio tracks
        for (var track in stream.getAudioTracks()) {
          track.enabled = true;
        }

        // 🌐 Web audio playback fix — reuse HTML AudioElement
        if (kIsWeb) {
          try {
            if (_webAudioElement == null) {
              _webAudioElement = html.AudioElement()
                ..autoplay = true
                ..controls = false;
              html.document.body?.append(_webAudioElement!);
            }

            // Attach stream to audio element
            // ignore: undefined_prefixed_name
            _webAudioElement!.srcObject = stream as dynamic;
            _webAudioElement!.muted = false;

            // Some browsers require a user gesture; attempt play and ignore aborts
            await _webAudioElement!.play().catchError((e) {
              debugPrint('⚠ WebAudio play error: $e');
            });

            debugPrint('✅ remote audio play OK');
          } catch (e) {
            debugPrint('⚠ Remote audio playback error (web): $e');
          }
        }
      } catch (e) {
        debugPrint('⚠ Remote audio handling error: $e');
      }
    };

    // 🎯 Call ended handler
    _callManager.onCallEnded = () {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    };

    // Start the call
    _startCall();
  }

  Future<void> _startCall() async {
    try {
      await _callManager.init();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠ Permission error: $e")));
      Navigator.pop(context);
      return;
    }

    if (widget.isCaller) {
      await _callManager.startCall(
        targetId: widget.targetUserId,
        isVideo: widget.isVideo,
      );
    } else if (widget.offerSignal != null) {
      await _callManager.answerCall(
        fromId: widget.targetUserId,
        signal: widget.offerSignal!,
      );
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _callManager.localStream != null) setState(() {});
    });
  }

  /// 🎙 Mute / Unmute
  void _toggleMute() {
    final stream = _callManager.localStream;
    if (stream == null) return;

    for (var track in stream.getAudioTracks()) {
      track.enabled = !track.enabled;
    }
    setState(() => _isMuted = !_isMuted);
  }

  /// 🔊 Toggle speakerphone
  Future<void> _toggleSpeaker() async {
    try {
      if (kIsWeb) return; // Web has no native speaker control
      await Helper.setSpeakerphoneOn(!_isSpeakerOn);
      setState(() => _isSpeakerOn = !_isSpeakerOn);
    } catch (e) {
      debugPrint("⚠ Speaker toggle error: $e");
    }
  }

  /// ➕ Add participant
  void _inviteParticipant() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Participant"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Enter user ID"),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Invite"),
            onPressed: () {
              final newUserId = controller.text.trim();
              if (newUserId.isNotEmpty) {
                _callManager.inviteParticipant(
                  targetId: newUserId,
                  roomId: _callManager.currentRoomId,
                  isVideo: widget.isVideo,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invitation sent to $newUserId'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _localRenderer.dispose();

    // ✅ Clean up web audio element
    if (_webAudioElement != null) {
      try {
        _webAudioElement!.pause();
        _webAudioElement!.remove();
      } catch (e) {
        debugPrint("⚠ Error removing web audio element: $e");
      }
      _webAudioElement = null;
    }

    Future.microtask(() async {
      _callManager.endCall(forceTargetId: widget.targetUserId);
      _callManager.dispose();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isVideo ? 'Video Call' : 'Audio Call';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.deepPurple),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// --- MEDIA AREA --- ///
            Expanded(
              child: widget.isVideo
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Container(
                            color: Colors.black,
                            child: RTCVideoView(
                              _remoteRenderer,
                              mirror: false,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black26,
                            ),
                            child: RTCVideoView(
                              _localRenderer,
                              mirror: true,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 1,
                          height: 1,
                          child: RTCVideoView(_remoteRenderer),
                        ),
                        Icon(
                          _connected ? Icons.headset : Icons.call,
                          size: 120,
                          color: _connected
                              ? Colors.greenAccent
                              : Colors.deepPurple,
                        ),
                      ],
                    ),
            ),

            /// --- STATUS --- ///
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                widget.isCaller
                    ? 'Calling ${widget.targetUserId}...'
                    : _connected
                    ? 'Connected'
                    : 'Connecting...',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            /// --- CONTROLS --- ///
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Colors.black87,
                border: Border(
                  top: BorderSide(color: Colors.white24, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _controlButton(
                    color: _isMuted ? Colors.orange : Colors.blue,
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onTap: _toggleMute,
                  ),
                  _controlButton(
                    color: _isSpeakerOn ? Colors.green : Colors.grey,
                    icon: _isSpeakerOn
                        ? Icons.volume_up
                        : Icons.volume_down_outlined,
                    onTap: _toggleSpeaker,
                  ),
                  _controlButton(
                    color: Colors.purple,
                    icon: Icons.person_add,
                    onTap: _inviteParticipant,
                  ),
                  _controlButton(
                    color: Colors.red,
                    icon: Icons.call_end,
                    onTap: () {
                      _callManager.endCall(forceTargetId: widget.targetUserId);
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CircleAvatar(
      backgroundColor: color,
      radius: 28,
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}
