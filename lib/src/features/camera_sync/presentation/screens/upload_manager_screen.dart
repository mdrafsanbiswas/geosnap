import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_event.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
import '../components/uplode_image_components/upload_manager_components.dart';
import '../constants/camera_sync_ui_color.dart';
import '../constants/camera_sync_ui_text.dart';
import 'image_preview_screen.dart';

class UploadManagerScreen extends StatelessWidget {
  const UploadManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UploadQueueBloc, UploadQueueState>(
      listenWhen: (previous, current) => previous.message != current.message,
      listener: (context, state) {
        final message = state.message;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<UploadQueueBloc>().add(const UploadQueueMessageCleared());
      },
      child: Scaffold(
        backgroundColor: CameraSyncUiColor.uploadManagerBackground,
        appBar: AppBar(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          backgroundColor: Colors.transparent,
          leadingWidth: 56,
          leading: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.chevron_left_rounded),
            iconSize: 34,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          ),
          title: const Text(CameraSyncUiText.uploadManagerTitle),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: BlocBuilder<UploadQueueBloc, UploadQueueState>(
            builder: (context, state) {
              final sortedItems = [...state.items]
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              final previewPaths = sortedItems
                  .map((item) => item.filePath)
                  .toList(growable: false);
              final hasUploads = sortedItems.isNotEmpty;

              return Column(
                children: [
                  if (hasUploads) ...[
                    UploadSummaryCard(state: state),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: !hasUploads
                        ? EmptyUploadState(isOnline: state.isOnline)
                        : ListView.builder(
                            itemCount: sortedItems.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemBuilder: (context, index) {
                              return UploadItemCard(
                                item: sortedItems[index],
                                onPreview: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ImagePreviewScreen(
                                      filePaths: previewPaths,
                                      initialIndex: index,
                                      title: CameraSyncUiText
                                          .queuedUploadPreviewTitle,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: CameraSyncUiColor.queueBadge,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text(CameraSyncUiText.startNewUploadBatch),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
