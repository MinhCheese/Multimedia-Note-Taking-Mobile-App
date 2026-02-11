import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String? fileName;
  const AudioPlayerWidget({super.key, required this.audioUrl,this.fileName,});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration=Duration.zero; // Tổng thời lượng của file
  Duration _position=Duration.zero;// Vị trí phát hiện tại
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
  @override
  void initState()
  {
    super.initState();
    //Lấy tổng thời lượng của video khi tải
    _player.onDurationChanged.listen((d){
      setState(() =>_duration=d);
    });
    //Lấy thời gian hiện tại của bản ghi âm(đơn vị mili giây)
    _player.onPositionChanged.listen((p){
      setState(() =>_position=p);
    });
    //Chỉnh trạng thái thanh trang thái khi nghe hết
    _player.onPlayerComplete.listen((event){
      setState(() {
        _isPlaying=false;
        _position=Duration.zero;
      });
    //Không được thiếu:Thiết lập nguồn âm thanh ngay sau khi khởi tạo có được tổng thời lượng
    _player.setSourceUrl(widget.audioUrl);
    });
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.fileName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                widget.fileName!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    //1.Nút play/pause
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 32,
                      ),
                      onPressed: _togglePlayback,
                    ),
                    //2.Thanh trượt video slider
                    Expanded(child: Slider(
                        min: 0.0,
                        max: _duration.inSeconds.toDouble(),
                        //Đảm bảo value không vươ quá max ==>Tránh lỗi tràn video
                        value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                        onChanged: (double value){
                          final newPosition=Duration(seconds: value.round());
                          //Seeking tua video
                          _player.seek(newPosition);
                          //Cập nhật đoạn tua video
                          setState(() =>_position=newPosition);
                        },
                    ),
                    ),

                    //3. Hiển thị thời gian ghi âm
                    Text('${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: const TextStyle(fontSize: 12 ),),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _formatDuration(Duration d){
    //Chuyển đổi duration thành mm:ss
    final minutes=d.inMinutes.remainder(60).toString().padLeft(2,'0');
    final seconds=d.inSeconds.remainder(60).toString().padLeft(2,'0');
    return "$minutes:$seconds";
  }
}
