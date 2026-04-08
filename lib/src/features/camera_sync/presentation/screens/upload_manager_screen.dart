import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/upload_item.dart';
import '../../domain/entities/upload_status.dart';
import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_event.dart';
import '../bloc/upload_queue/upload_queue_state.dart';
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
        backgroundColor: const Color(0xFF081022),
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
          title: const Text('Upload Manager'),
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
                    _SummaryCard(state: state),
                    const SizedBox(height: 12),
                  ],
                  Expanded(
                    child: !hasUploads
                        ? _EmptyUploadState(isOnline: state.isOnline)
                        : ListView.builder(
                            itemCount: sortedItems.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemBuilder: (context, index) {
                              return _UploadItemCard(
                                item: sortedItems[index],
                                onPreview: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ImagePreviewScreen(
                                      filePaths: previewPaths,
                                      initialIndex: index,
                                      title: 'Queued Upload Preview',
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
                        backgroundColor: const Color(0xFF2B79FF),
                      ),
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Start New Upload Batch'),
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

class _EmptyUploadState extends StatelessWidget {
  const _EmptyUploadState({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final statusText = isOnline
        ? 'New uploads will appear here and start syncing automatically.'
        : 'You are offline. Captured photos will queue here and auto-resume once internet is back.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF0F1A36),
            border: Border.all(color: const Color(0x334885FF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_upload_outlined, color: Colors.white70),
              const SizedBox(height: 12),
              const Text(
                'No uploads yet',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final UploadQueueState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0F1A36),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Batch Sync Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: state.isOnline
                      ? const Color(0x2238D996)
                      : const Color(0x33F09B4E),
                ),
                child: Text(
                  state.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: state.isOnline
                        ? const Color(0xFF67E7B2)
                        : const Color(0xFFFFC38C),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: state.overallProgress,
            minHeight: 6,
            backgroundColor: const Color(0xFF263457),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3E8DFF)),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 10),
          Text(
            '${state.uploadedCount}/${state.totalCount} uploaded • '
            '${state.retryableCount} pending',
            style: const TextStyle(color: Colors.white70),
          ),
          if (state.lastSyncedAt != null)
            Text(
              'Last sync: ${state.lastSyncedAt!.toLocal()}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _UploadItemCard extends StatelessWidget {
  const _UploadItemCard({required this.item, required this.onPreview});

  final UploadItem item;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return GestureDetector(
      onTap: onPreview,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF111C39),
          border: Border.all(color: statusColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            _Thumb(filePath: item.filePath),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.basename(item.filePath),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatusChip(label: item.status.label, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        '${(item.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (item.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.errorMessage!,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.open_in_full_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(
            color: Color(0xFF263457),
            child: Icon(
              Icons.insert_drive_file,
              color: Colors.white70,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Color _statusColor(UploadStatus status) {
  switch (status) {
    case UploadStatus.pending:
      return const Color(0xFF9FB2D9);
    case UploadStatus.uploading:
      return const Color(0xFF56AAFF);
    case UploadStatus.uploaded:
      return const Color(0xFF60E0AE);
    case UploadStatus.failed:
      return const Color(0xFFFF7B7B);
    case UploadStatus.waitingForNetwork:
      return const Color(0xFFFFB668);
  }
}
