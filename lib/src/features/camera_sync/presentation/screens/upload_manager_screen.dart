import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/upload_item.dart';
import '../../domain/entities/upload_status.dart';
import '../bloc/upload_queue/upload_queue_bloc.dart';
import '../bloc/upload_queue/upload_queue_event.dart';
import '../bloc/upload_queue/upload_queue_state.dart';

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
          backgroundColor: Colors.transparent,
          title: const Text('Upload Manager'),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: BlocBuilder<UploadQueueBloc, UploadQueueState>(
            builder: (context, state) {
              final sortedItems = [...state.items]
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              return Column(
                children: [
                  _SummaryCard(state: state),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state.retryableCount == 0
                                ? null
                                : () => context.read<UploadQueueBloc>().add(
                                    const UploadQueueProcessRequested(),
                                  ),
                            icon: const Icon(Icons.sync),
                            label: const Text('Retry Pending'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .read<UploadQueueBloc>()
                                .add(const UploadQueueRefreshed()),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Refresh'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: sortedItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No pending uploads.',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: sortedItems.length,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemBuilder: (context, index) {
                              return _UploadItemCard(item: sortedItems[index]);
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
  const _UploadItemCard({required this.item});

  final UploadItem item;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);

    return Container(
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
        ],
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
