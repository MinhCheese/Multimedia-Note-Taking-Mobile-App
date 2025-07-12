import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  const AudioPlayerWidget({super.key, required this.audioUrl});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.audioUrl));
    }

    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
          onPressed: _togglePlayback,
        ),
        Expanded(
          child: Text(
            widget.audioUrl.split('/').last,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
