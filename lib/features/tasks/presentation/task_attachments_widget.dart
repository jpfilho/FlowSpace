import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../../core/theme/index.dart';
import '../../auth/domain/data_providers.dart';
import '../../auth/domain/auth_provider.dart';

// ── Model ─────────────────────────────────────────────────────
class AttachmentData {
  final String id;
  final String taskId;
  final String uploadedBy;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String storagePath;
  final DateTime createdAt;

  const AttachmentData({
    required this.id,
    required this.taskId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.storagePath,
    required this.createdAt,
  });

  factory AttachmentData.fromJson(Map<String, dynamic> j) => AttachmentData(
        id: j['id'] as String,
        taskId: j['task_id'] as String,
        uploadedBy: j['uploaded_by'] as String,
        fileName: j['file_name'] as String,
        fileSize: (j['file_size'] as num?)?.toInt() ?? 0,
        mimeType: j['mime_type'] as String? ?? 'application/octet-stream',
        storagePath: j['storage_path'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  String get sizeDisplay {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  IconData get icon {
    if (mimeType.startsWith('image/')) return Icons.image_rounded;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description_rounded;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart_rounded;
    }
    if (mimeType.contains('zip') || mimeType.contains('tar')) {
      return Icons.folder_zip_rounded;
    }
    return Icons.attach_file_rounded;
  }

  Color get iconColor {
    if (mimeType.startsWith('image/')) return AppColors.primary;
    if (mimeType.contains('pdf')) return AppColors.error;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return const Color(0xFF2B579A);
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return const Color(0xFF217346);
    }
    return AppColors.textMuted;
  }
}

// ── Provider ─────────────────────────────────────────────────
final taskAttachmentsProvider = FutureProvider.autoDispose
    .family<List<AttachmentData>, String>((ref, taskId) async {
  final client = ref.read(supabaseProvider);
  final data = await client
      .from('task_attachments')
      .select()
      .eq('task_id', taskId)
      .order('created_at', ascending: false);
  return (data as List)
      .cast<Map<String, dynamic>>()
      .map(AttachmentData.fromJson)
      .toList();
});

// ── Upload helper ─────────────────────────────────────────────
Future<void> uploadAttachment(
    WidgetRef ref, String taskId, BuildContext context) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return;

  final file = result.files.first;
  if (file.bytes == null) return;

  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final client = ref.read(supabaseProvider);
  final fileName = file.name;
  final storagePath = 'tasks/$taskId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

  try {
    // Upload to Supabase Storage (bucket: task-files)
    await client.storage.from('task-files').uploadBinary(
          storagePath,
          file.bytes!,
          fileOptions: FileOptions(contentType: file.extension ?? 'application/octet-stream'),
        );

    // Save metadata
    await client.from('task_attachments').insert({
      'task_id': taskId,
      'uploaded_by': user.id,
      'file_name': fileName,
      'file_size': file.size,
      'mime_type': _mimeFromExt(file.extension),
      'storage_path': storagePath,
    });

    // ignore: unused_result
    ref.invalidate(taskAttachmentsProvider(taskId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileName enviado com sucesso'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar arquivo: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

String _mimeFromExt(String? ext) {
  switch (ext?.toLowerCase()) {
    case 'jpg':
    case 'jpeg': return 'image/jpeg';
    case 'png': return 'image/png';
    case 'gif': return 'image/gif';
    case 'webp': return 'image/webp';
    case 'pdf': return 'application/pdf';
    case 'doc': return 'application/msword';
    case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    case 'xls': return 'application/vnd.ms-excel';
    case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    case 'zip': return 'application/zip';
    case 'txt': return 'text/plain';
    default: return 'application/octet-stream';
  }
}

// ═══════════════════════════════════════════════════════════════
// ATTACHMENTS SECTION WIDGET (used in task_detail_page)
// ═══════════════════════════════════════════════════════════════

class AttachmentsSection extends ConsumerWidget {
  final String taskId;
  const AttachmentsSection({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(taskId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          const Icon(Icons.attach_file_rounded,
              size: 18, color: AppColors.warning),
          const SizedBox(width: 8),
          Text('Anexos',
              style:
                  context.bodyMd.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          attachmentsAsync.maybeWhen(
            data: (files) => files.isEmpty
                ? const SizedBox.shrink()
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text('${files.length}',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning)),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const Spacer(),
          // Upload button
          GestureDetector(
            onTap: () => uploadAttachment(ref, taskId, context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Row(children: [
                Icon(Icons.upload_rounded,
                    size: 14, color: AppColors.warning),
                SizedBox(width: 4),
                Text('Enviar',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.sp12),

        // File list
        attachmentsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary)),
          error: (e, _) => Text('Erro: $e',
              style: context.bodySm.copyWith(color: AppColors.error)),
          data: (files) => files.isEmpty
              ? _EmptyAttachments(taskId: taskId)
              : Column(
                  children: files
                      .map((f) => _AttachmentTile(
                            attachment: f,
                            taskId: taskId,
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _EmptyAttachments extends ConsumerWidget {
  final String taskId;
  const _EmptyAttachments({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => uploadAttachment(ref, taskId, context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.sp16),
        decoration: BoxDecoration(
          color: context.isDark
              ? AppColors.surfaceVariantDark
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: context.isDark
                ? AppColors.borderDark
                : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(children: [
          Icon(Icons.cloud_upload_outlined,
              size: 32, color: context.cTextMuted),
          const SizedBox(height: 8),
          Text('Clique para enviar um arquivo',
              style: context.bodySm.copyWith(color: context.cTextMuted)),
        ]),
      ),
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  final AttachmentData attachment;
  final String taskId;
  const _AttachmentTile({required this.attachment, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sp8),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sp12, vertical: AppSpacing.sp10),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: context.isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: attachment.iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(attachment.icon,
              color: attachment.iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sp12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.fileName,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.cTextPrimary),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${attachment.sizeDisplay} · ${_fmtDate(attachment.createdAt)}',
                style: TextStyle(
                    fontSize: 11, color: context.cTextMuted),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded,
              size: 16, color: AppColors.error),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          tooltip: 'Remover anexo',
          onPressed: () async {
            final client = ref.read(supabaseProvider);
            try {
              await client.storage
                  .from('task-files')
                  .remove([attachment.storagePath]);
            } catch (_) {
              // Storage might not exist yet, still remove metadata
            }
            await client
                .from('task_attachments')
                .delete()
                .eq('id', attachment.id);
            // ignore: unused_result
            ref.invalidate(taskAttachmentsProvider(taskId));
          },
        ),
      ]),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
