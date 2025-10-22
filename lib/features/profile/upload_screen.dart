import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:musicapp/data/services/api_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _apiService = ApiService();

  File? _mediaFile;
  File? _coverArtFile;
  bool _isLoading = false;
  String? _errorMessage;

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
      if (_mediaFile == null) {
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
        final result = await _apiService.uploadMedia(
          _titleController.text,
          _mediaFile!,
          coverArtFile: _coverArtFile,
        );

        if (mounted) {
          if (result['error'] == false) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Upload successful!')));
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
      appBar: AppBar(title: const Text('Upload Media')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator:
                    (value) => value!.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 24),
              _buildFilePickerRow(
                'Media File (mp3, mp4)',
                _mediaFile,
                _pickMediaFile,
              ),
              const SizedBox(height: 16),
              _buildFilePickerRow(
                'Cover Art (Optional)',
                _coverArtFile,
                _pickCoverArt,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(onPressed: _upload, child: const Text('Upload')),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePickerRow(String label, File? file, VoidCallback onPressed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          file?.path.split(Platform.pathSeparator).last ?? 'No file selected',
        ),
        TextButton(onPressed: onPressed, child: const Text('Select File')),
      ],
    );
  }
}
