import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class MessageInput extends StatelessWidget {
  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onTyping,
    this.hintText = 'Type a message...',
  });

  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final ValueChanged<String>? onTyping;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    void sendMessage() {
      final String message = controller.text.trim();
      if (message.isEmpty) {
        return;
      }
      onSend(message);
      controller.clear();
      onTyping?.call('');
    }

    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: AppPaddings.allSm,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onTyping,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => sendMessage(),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.canvasWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.lg,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.lg,
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.lg,
                    borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.4),
                  ),
                ),
              ),
            ),
            AppGaps.wSM,
            Material(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(AppSizes.max),
              child: InkWell(
                onTap: sendMessage,
                borderRadius: BorderRadius.circular(AppSizes.max),
                child: const SizedBox(
                  width: AppSizes.huge,
                  height: AppSizes.huge,
                  child: Icon(
                    Icons.send_rounded,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
