import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:musicapp/data/services/database_service.dart';
import 'package:musicapp/data/models/media.dart';

class UploadScreen extends StatefulWidget {
  final Media? mediaToEdit;
  const UploadScreen({super.key, this.mediaToEdit});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _dbService = DatabaseService();

  File? _mediaFile;
  File? _coverArtFile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.mediaToEdit != null) {
      _titleController.text = widget.mediaToEdit!.title;
      // Pre-fill files if they exist, for display purposes
      if (widget.mediaToEdit!.filePath.isNotEmpty) {
        _mediaFile = File(widget.mediaToEdit!.filePath);
      }
      if (widget.mediaToEdit!.coverArtPath != null &&
          widget.mediaToEdit!.coverArtPath!.isNotEmpty) {
        _coverArtFile = File(widget.mediaToEdit!.coverArtPath!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickMediaFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'mp4', 'm4a', 'mov'],
    );

    if (result != null) {
      setState(() {
        _mediaFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickCoverArt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _coverArtFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _upload() async {
    if (_formKey.currentState!.validate()) {
      if (_mediaFile == null && widget.mediaToEdit == null) {
        setState(() {
          _errorMessage = 'Please select a media file to upload.';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final Map<String, dynamic> result;
        if (widget.mediaToEdit != null) {
          // This is an update operation
          result = await _dbService.updateMedia(
            widget.mediaToEdit!.id,
            _titleController.text,
            newMediaFile: _mediaFile,
            newCoverArtFile: _coverArtFile,
          );
        } else {
          // This is a new upload
          result = await _dbService.uploadMedia(
            _titleController.text,
            _mediaFile!,
            coverArtFile: _coverArtFile,
          );
        }

        if (mounted) {
          if (result['error'] == false) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.mediaToEdit != null
                      ? 'Update successful!'
                      : 'Upload successful!',
                ),
              ),
            );
            // Pop back to the profile screen, passing 'true' to indicate success
            Navigator.of(context).pop(true);
          } else {
            setState(() {
              _errorMessage = result['message'];
            });
          }
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mediaToEdit != null ? 'Edit Media' : 'Upload Media'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                validator:
                    (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),
              _buildFilePickerCard(
                label: 'Media File',
                file: _mediaFile,
                onPressed: _pickMediaFile,
                icon: Icons.music_video,
                allowedExtensions: 'mp3, mp4, m4a, mov',
              ),
              const SizedBox(height: 16),
              _buildFilePickerCard(
                label: 'Cover Art (Optional)',
                file: _coverArtFile,
                onPressed: _pickCoverArt,
                icon: Icons.image,
                allowedExtensions: 'jpg, png',
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton.icon(
                  onPressed: _upload,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(
                    widget.mediaToEdit != null
                        ? 'UPDATE MEDIA'
                        : 'UPLOAD MEDIA',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerCard({
    required String label,
    required File? file,
    required VoidCallback onPressed,
    required IconData icon,
    required String allowedExtensions,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
      ),
      elevation: 0,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              if (file != null && label.contains('Cover Art'))
                Image.file(file, width: 48, height: 48, fit: BoxFit.cover)
              else
                Icon(
                  icon,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      file != null
                          ? p.basename(file.path)
                          : 'No file selected ($allowedExtensions)',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
