import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../services/class_files.dart';

/// A local file row, converted from a `ClassFile` or `YearFile` row.
class AttachedFile {
  final int id;
  final String fileName;
  final String storedPath;
  final int sizeBytes;

  const AttachedFile({
    required this.id,
    required this.fileName,
    required this.storedPath,
    required this.sizeBytes,
  });
}

/// Local-file list with add/open/delete, shared by class and academic-year
/// attachments. File behavior is injected; errors surface as snackbars.
class AttachmentPanel extends StatefulWidget {
  final AsyncValue<List<AttachedFile>> files;
  final Future<void> Function() onAdd;
  final Future<void> Function(AttachedFile file) onOpen;
  final Future<void> Function(AttachedFile file) onDelete;

  const AttachmentPanel({
    super.key,
    required this.files,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  State<AttachmentPanel> createState() => _AttachmentPanelState();
}

class _AttachmentPanelState extends State<AttachmentPanel> {
  bool _busy = false;

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onAdd();
    } catch (e) {
      if (mounted) {
        final message =
            ClassFilesService.pickErrorKind(e) == 'unreadable'
            ? context.l10n.couldNotAccessFile
            : context.l10n.couldNotPickFiles('$e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(AttachedFile row) async {
    try {
      await widget.onOpen(row);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotOpenFile('$e'))),
        );
      }
    }
  }

  Future<void> _delete(AttachedFile row) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteFileTitle),
        content: Text(context.l10n.deleteFileBody(row.fileName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onDelete(row);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotLoadFiles('$e'))),
        );
      }
    }
  }

  IconData _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_outlined;
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return Icons.slideshow_outlined;
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _subtitle(AttachedFile row) {
    final ext = ClassFilesService.extensionOf(row.fileName);
    final size = _formatSize(row.sizeBytes);
    return ext.isEmpty ? size : '$ext · $size';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.classFilesSection,
                style: theme.textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: context.l10n.addFiles,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              onPressed: _busy ? null : _add,
            ),
          ],
        ),
        widget.files.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
          error: (e, _) => Text(context.l10n.couldNotLoadFiles('$e')),
          data: (list) {
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(context.l10n.noFilesYet),
              );
            }
            return Column(
              children: [
                for (final f in list)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _iconFor(f.fileName),
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      f.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(_subtitle(f)),
                    onTap: () => _open(f),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: context.l10n.openFileTooltip,
                          icon: const Icon(Icons.open_in_new_outlined),
                          onPressed: () => _open(f),
                        ),
                        IconButton(
                          tooltip: context.l10n.deleteFileTooltip,
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(f),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
