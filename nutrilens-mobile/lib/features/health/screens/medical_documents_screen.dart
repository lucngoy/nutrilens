import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../providers/health_provider.dart';
import '../models/medical_document_model.dart';

class MedicalDocumentsScreen extends ConsumerStatefulWidget {
  const MedicalDocumentsScreen({super.key});

  @override
  ConsumerState<MedicalDocumentsScreen> createState() =>
      _MedicalDocumentsScreenState();
}

class _MedicalDocumentsScreenState
    extends ConsumerState<MedicalDocumentsScreen> {
  static const primaryColor = Color(0xFFEC6F2D);
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterType; // null = all

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(medicalDocumentsProvider.notifier).fetchDocuments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicalDocumentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.canPop()
                              ? context.pop()
                              : context.go('/profile'),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chevron_left,
                                color: primaryColor, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Medical Documents',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A1A))),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showFilterSheet(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _filterType != null
                                  ? primaryColor.withOpacity(0.12)
                                  : const Color(0xFFF0F0F0),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.filter_list_rounded,
                                color: _filterType != null
                                    ? primaryColor
                                    : Colors.grey,
                                size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showUploadSheet(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEC6F2D), Color(0xFFFF9A5C)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    hintStyle:
                        const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.grey, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: primaryColor, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Body
          Expanded(
            child: state.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: primaryColor)),
              error: (e, _) => Center(
                  child: Text(e.toString(),
                      style: const TextStyle(color: Colors.red))),
              data: (docs) {
                final filtered = docs.where((d) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      d.documentType.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesType = _filterType == null || d.documentType == _filterType;
                  return matchesSearch && matchesType;
                }).toList();
                return filtered.isEmpty
                    ? _buildEmpty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => Dismissible(
                          key: ValueKey(filtered[i].id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => AppDialogs.warning(
                            context,
                            title: 'Delete Document',
                            message: 'Delete "${filtered[i].title}"? This cannot be undone.',
                            confirmLabel: 'Delete',
                          ),
                          onDismissed: (_) async {
                            try {
                              await ref
                                  .read(medicalDocumentsProvider.notifier)
                                  .deleteDocument(filtered[i].id);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red));
                              }
                            }
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_rounded,
                                    color: Colors.white, size: 24),
                                SizedBox(height: 4),
                                Text('Delete',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          child: _DocumentCard(
                            doc: filtered[i],
                            onEdit: () => _showEditSheet(context, filtered[i]),
                            onDelete: () => _confirmDelete(context, filtered[i]),
                          ),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_outlined,
              size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No documents yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          const Text('Upload lab results, prescriptions or reports',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUploadSheet(context),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload Document'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, MedicalDocument doc) {
    final titleController = TextEditingController(text: doc.title);
    final notesController = TextEditingController(text: doc.notes);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFDDDDDD),
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Edit Document',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: _inputDecoration('Title'),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: _inputDecoration('Notes (optional)'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;
                          setModalState(() => isSaving = true);
                          try {
                            await ref
                                .read(medicalDocumentsProvider.notifier)
                                .updateDocument(doc.id,
                                    title: title,
                                    notes: notesController.text.trim());
                            if (context.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red));
                            }
                          } finally {
                            setModalState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    const types = {
      null: 'All types',
      'blood_test': 'Blood Test',
      'prescription': 'Prescription',
      'report': 'Medical Report',
      'other': 'Other',
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Filter by type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 12),
            ...types.entries.map((e) => InkWell(
                  onTap: () {
                    setState(() => _filterType = e.key);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    decoration: BoxDecoration(
                      color: _filterType == e.key
                          ? primaryColor.withOpacity(0.08)
                          : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(12),
                      border: _filterType == e.key
                          ? Border.all(color: primaryColor.withOpacity(0.3))
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.value,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _filterType == e.key
                                    ? primaryColor
                                    : const Color(0xFF1A1A1A))),
                        if (_filterType == e.key)
                          const Icon(Icons.check_rounded,
                              color: primaryColor, size: 18),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'blood_test';
    File? selectedFile;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Upload Document',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),

              // Title
              _FieldLabel('Title'),
              const SizedBox(height: 6),
              TextField(
                controller: titleController,
                decoration: _inputDecoration('e.g. Blood test March 2026'),
              ),
              const SizedBox(height: 16),

              // Type
              _FieldLabel('Document Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'blood_test',
                  'prescription',
                  'report',
                  'other',
                ].map((type) {
                  final selected = selectedType == type;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? primaryColor
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_typeLabel(type),
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF1A1A1A))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // File picker
              _FieldLabel('File'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 85);
                  if (picked != null) {
                    setModalState(() => selectedFile = File(picked.path));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: selectedFile != null
                            ? primaryColor
                            : const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selectedFile != null
                            ? Icons.check_circle_outline
                            : Icons.upload_file_outlined,
                        color: selectedFile != null
                            ? primaryColor
                            : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedFile != null
                              ? selectedFile!.path.split('/').last
                              : 'Tap to select a file',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 13,
                              color: selectedFile != null
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              _FieldLabel('Notes (optional)'),
              const SizedBox(height: 6),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: _inputDecoration('Additional notes...'),
              ),
              const SizedBox(height: 24),

              // Upload button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please enter a title')));
                            return;
                          }
                          if (selectedFile == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Please select a file')));
                            return;
                          }
                          setModalState(() => isUploading = true);
                          try {
                            await ref
                                .read(medicalDocumentsProvider.notifier)
                                .uploadDocument(
                                  file: selectedFile!,
                                  title: titleController.text.trim(),
                                  documentType: selectedType,
                                  notes: notesController.text.trim(),
                                );
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: Colors.red));
                            }
                          } finally {
                            setModalState(() => isUploading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Upload',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MedicalDocument doc) async {
    final confirmed = await AppDialogs.warning(
      context,
      title: 'Delete Document',
      message: 'Delete "${doc.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed) {
      try {
        await ref
            .read(medicalDocumentsProvider.notifier)
            .deleteDocument(doc.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'blood_test': return 'Blood Test';
      case 'prescription': return 'Prescription';
      case 'report': return 'Medical Report';
      default: return 'Other';
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ── Document Card ─────────────────────────────────────────────────────────────

class _DocumentCard extends StatelessWidget {
  final MedicalDocument doc;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DocumentCard({required this.doc, required this.onEdit, required this.onDelete});

  static const primaryColor = Color(0xFFEC6F2D);

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(doc.documentType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(doc.documentType),
                color: typeColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A))),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(doc.documentTypeLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: typeColor)),
                    ),
                    const SizedBox(width: 8),
                    Text(_formatDate(doc.uploadedAt),
                        style: const TextStyle(
                            fontSize: 11, color: Colors.grey)),
                  ],
                ),
                if (doc.notes.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(doc.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),

          // Edit
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Color(0xFF4A6CF7), size: 16),
            ),
          ),
          const SizedBox(width: 6),
          // Delete
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'blood_test': return Icons.bloodtype_outlined;
      case 'prescription': return Icons.medication_outlined;
      case 'report': return Icons.description_outlined;
      default: return Icons.folder_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'blood_test': return const Color(0xFFE74C3C);
      case 'prescription': return const Color(0xFF3498DB);
      case 'report': return const Color(0xFF27AE60);
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A)));
  }
}
