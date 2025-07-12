import 'package:flutter/material.dart';

class DeleteNoteDialog extends StatelessWidget {
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const DeleteNoteDialog({
    Key? key,
    this.onConfirm,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(0xFF6B7B6B), // Dark green-gray color
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            const Text(
              'Xóa ghi chú?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle
            const Text(
              'Bạn có chắc muốn xóa dữ liệu sẽ\nkhông được lưu lại',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 32),

            // Buttons
            Row(
              children: [
                // Cancel Button
                Expanded(
                  child: Container(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {

                        onCancel?.call();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Delete Button
                Expanded(
                  child: Container(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {

                        onConfirm?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB83D8E), // Purple-magenta color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xóa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Static method to show the dialog
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return DeleteNoteDialog(
          onConfirm: () {
            Navigator.of(context).pop(true);
          },
          onCancel: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }
}