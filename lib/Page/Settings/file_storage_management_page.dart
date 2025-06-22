import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:next_level/General/app_colors.dart';
import 'package:next_level/Service/navigator_service.dart';
import 'package:next_level/Service/file_storage_service.dart';

class FileStorageManagementPage extends StatefulWidget {
  const FileStorageManagementPage({super.key});

  @override
  State<FileStorageManagementPage> createState() => _FileStorageManagementPageState();
}

class _FileStorageManagementPageState extends State<FileStorageManagementPage> {
  List<File> attachmentFiles = [];
  Map<String, dynamic> storageStats = {};
  bool isLoading = true;
  final _fileStorageService = FileStorageService.instance;

  @override
  void initState() {
    super.initState();
    _loadAttachmentFiles();
  }

  Future<void> _loadAttachmentFiles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final files = await _fileStorageService.getAllAttachmentFiles();
      final stats = await _fileStorageService.getStorageStats();

      setState(() {
        attachmentFiles = files;
        storageStats = stats;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading attachment files: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _downloadAllFiles() async {
    if (attachmentFiles.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download All Files'),
        content: Text('Download all ${attachmentFiles.length} files to Downloads/Next Level folder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.main),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _fileStorageService.downloadAllFiles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'All files downloaded to Downloads/Next Level' : 'Some files could not be downloaded'),
              backgroundColor: success ? AppColors.green : AppColors.orange,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error downloading files: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error downloading files'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _downloadSingleFile(File file) async {
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $fileName'),
            Text('Size: ${_fileStorageService.formatFileSize(fileSize)}'),
            const SizedBox(height: 8),
            const Text('Download this file to Downloads/Next Level folder?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.main),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _fileStorageService.downloadFile(file, null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'File downloaded to Downloads/Next Level' : 'Could not download file'),
              backgroundColor: success ? AppColors.green : AppColors.red,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error downloading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error downloading file'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return Icons.image_rounded;
    } else if (['.pdf'].contains(extension)) {
      return Icons.picture_as_pdf_rounded;
    } else if (['.doc', '.docx'].contains(extension)) {
      return Icons.description_rounded;
    } else if (['.xls', '.xlsx'].contains(extension)) {
      return Icons.table_chart_rounded;
    } else if (['.txt'].contains(extension)) {
      return Icons.text_snippet_rounded;
    } else if (['.zip', '.rar', '.7z'].contains(extension)) {
      return Icons.archive_rounded;
    } else {
      return Icons.insert_drive_file_rounded;
    }
  }

  bool _isImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _loadAttachmentFiles(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File deleted successfully'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error deleting file'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllFiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Files'),
        content: const Text('Are you sure you want to delete all attachment files? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _fileStorageService.deleteAllAttachments();
        if (success) {
          _loadAttachmentFiles();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All files deleted successfully'),
                backgroundColor: AppColors.green,
              ),
            );
          }
        } else {
          throw Exception('Failed to delete files');
        }
      } catch (e) {
        debugPrint('Error clearing files: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error deleting files'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  void _showFilePreview(String filePath) {
    if (_isImageFile(filePath)) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(path.basename(filePath)),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _downloadSingleFile(File(filePath));
                      },
                      tooltip: 'Download',
                    ),
                  ],
                ),
                Flexible(
                  child: Image.file(
                    File(filePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFileTypeCard(String title, int count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppColors.text.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Management'),
        leading: InkWell(
          borderRadius: AppColors.borderRadiusAll,
          onTap: () => NavigatorService().back(),
          child: const Icon(Icons.arrow_back_ios),
        ),
        actions: [
          if (attachmentFiles.isNotEmpty) ...[
            IconButton(
              onPressed: _downloadAllFiles,
              icon: const Icon(Icons.download_rounded),
              tooltip: 'Download All Files',
            ),
            IconButton(
              onPressed: _clearAllFiles,
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear All Files',
            ),
          ],
          IconButton(
            onPressed: _loadAttachmentFiles,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Storage Summary
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.storage_rounded,
                            color: AppColors.main,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Storage Summary',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Main stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Files',
                                style: TextStyle(
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${storageStats['totalFiles'] ?? 0}',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total Size',
                                style: TextStyle(
                                  color: AppColors.text.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _fileStorageService.formatFileSize(storageStats['totalSize'] ?? 0),
                                style: TextStyle(
                                  color: AppColors.main,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // File type breakdown
                      Row(
                        children: [
                          _buildFileTypeCard(
                            'Images',
                            storageStats['imageCount'] ?? 0,
                            Icons.image_rounded,
                            Colors.blue,
                          ),
                          _buildFileTypeCard(
                            'Documents',
                            storageStats['documentCount'] ?? 0,
                            Icons.description_rounded,
                            Colors.orange,
                          ),
                          _buildFileTypeCard(
                            'Others',
                            storageStats['otherCount'] ?? 0,
                            Icons.insert_drive_file_rounded,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Files List
                Expanded(
                  child: attachmentFiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 64,
                                color: AppColors.text.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No attachment files found',
                                style: TextStyle(
                                  color: AppColors.text.withValues(alpha: 0.6),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: attachmentFiles.length,
                          itemBuilder: (context, index) {
                            final file = attachmentFiles[index];
                            final fileName = path.basename(file.path);
                            final isImage = _isImageFile(file.path);

                            return FutureBuilder<int>(
                              future: file.length(),
                              builder: (context, sizeSnapshot) {
                                final fileSize = sizeSnapshot.data ?? 0;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.text.withValues(alpha: 0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.main.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: isImage && File(file.path).existsSync()
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(file.path),
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.broken_image_rounded,
                                                    color: AppColors.main,
                                                    size: 20,
                                                  );
                                                },
                                              ),
                                            )
                                          : Icon(
                                              _getFileIcon(file.path),
                                              color: AppColors.main,
                                              size: 20,
                                            ),
                                    ),
                                    title: Text(
                                      fileName,
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      _fileStorageService.formatFileSize(fileSize),
                                      style: TextStyle(
                                        color: AppColors.text.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () => _downloadSingleFile(file),
                                          icon: Icon(
                                            Icons.download_rounded,
                                            color: AppColors.main,
                                            size: 20,
                                          ),
                                          tooltip: 'Download',
                                        ),
                                        IconButton(
                                          onPressed: () => _deleteFile(file),
                                          icon: const Icon(
                                            Icons.delete_rounded,
                                            color: AppColors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                    onTap: isImage ? () => _showFilePreview(file.path) : () => _downloadSingleFile(file),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
