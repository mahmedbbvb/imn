import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../../core/utils/app_logger.dart';
import '../../services/encryption/encryption_service.dart';
import '../../services/webrtc/webrtc_service.dart';

const _chunkSize = 16 * 1024; // 16 KB chunks
const _uuid = Uuid();

enum FileTransferStatus {
  idle,
  encrypting,
  sending,
  receiving,
  assembling,
  complete,
  failed,
}

class FileTransferProgress {
  final String fileId;
  final String fileName;
  final int totalChunks;
  final int completedChunks;
  final FileTransferStatus status;

  FileTransferProgress({
    required this.fileId,
    required this.fileName,
    required this.totalChunks,
    required this.completedChunks,
    required this.status,
  });

  double get progress =>
      totalChunks == 0 ? 0 : completedChunks / totalChunks;
}

/// Handles chunked file transfer with encryption and integrity verification.
class FileTransferService {
  final EncryptionService _encryption;
  final WebRTCService _webrtc;

  final _progressController =
      StreamController<FileTransferProgress>.broadcast();

  // Track incoming file chunks
  final Map<String, List<Uint8List?>> _incomingChunks = {};
  final Map<String, Map<String, dynamic>> _incomingMeta = {};

  Stream<FileTransferProgress> get progress => _progressController.stream;

  FileTransferService({
    required EncryptionService encryption,
    required WebRTCService webrtc,
  })  : _encryption = encryption,
        _webrtc = webrtc {
    _listenForChunks();
  }

  // ── Send File ────────────────────────────────────────────────

  Future<String> sendFile({
    required String sessionId,
    required String conversationId,
    required File file,
    required String mimeType,
  }) async {
    final fileId = _uuid.v4();
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileBytes = await file.readAsBytes();
    final fileHash = sha256.convert(fileBytes).toString();

    _emitProgress(fileId, fileName, 0, 0, FileTransferStatus.encrypting);

    // Compute total chunks
    final totalChunks = (fileBytes.length / _chunkSize).ceil();

    // Send file metadata first
    await _webrtc.sendMessage(WebRTCMessage(
      type: 'file_start',
      id: fileId,
      payload: {
        'fileId': fileId,
        'fileName': fileName,
        'fileSize': fileBytes.length,
        'mimeType': mimeType,
        'totalChunks': totalChunks,
        'fileHash': fileHash,
        'conversationId': conversationId,
      },
    ));

    _emitProgress(fileId, fileName, totalChunks, 0,
        FileTransferStatus.sending);

    // Send chunks
    for (int i = 0; i < totalChunks; i++) {
      final start = i * _chunkSize;
      final end = (start + _chunkSize).clamp(0, fileBytes.length);
      final chunk = fileBytes.sublist(start, end);

      final encrypted = await _encryption.encryptChunk(
        sessionId: sessionId,
        chunk: chunk,
        chunkIndex: i,
        fileId: fileId,
      );

      await _webrtc.sendMessage(WebRTCMessage(
        type: 'file_chunk',
        id: fileId,
        payload: {
          'fileId': fileId,
          'chunkIndex': i,
          'totalChunks': totalChunks,
          'data': base64Url.encode(encrypted),
        },
      ));

      _emitProgress(fileId, fileName, totalChunks, i + 1,
          FileTransferStatus.sending);

      // Small delay to avoid overwhelming the data channel
      if (i % 10 == 9) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    // Send end marker
    await _webrtc.sendMessage(WebRTCMessage(
      type: 'file_end',
      id: fileId,
      payload: {'fileId': fileId},
    ));

    _emitProgress(fileId, fileName, totalChunks, totalChunks,
        FileTransferStatus.complete);
    appLogger.i('File sent: $fileName ($totalChunks chunks)');
    return fileId;
  }

  // ── Receive File ─────────────────────────────────────────────

  void _listenForChunks() {
    _webrtc.messages.listen((msg) async {
      switch (msg.type) {
        case 'file_start':
          _handleFileStart(msg);
          break;
        case 'file_chunk':
          await _handleFileChunk(msg);
          break;
        case 'file_end':
          await _handleFileEnd(msg);
          break;
        default:
          break;
      }
    });
  }

  void _handleFileStart(WebRTCMessage msg) {
    final meta = msg.payload as Map<String, dynamic>;
    final fileId = meta['fileId'] as String;
    final totalChunks = meta['totalChunks'] as int;
    _incomingMeta[fileId] = meta;
    _incomingChunks[fileId] = List.filled(totalChunks, null);
    _emitProgress(fileId, meta['fileName'] as String, totalChunks, 0,
        FileTransferStatus.receiving);
    appLogger.i('File transfer started: $fileId');
  }

  Future<void> _handleFileChunk(WebRTCMessage msg) async {
    final payload = msg.payload as Map<String, dynamic>;
    final fileId = payload['fileId'] as String;
    final chunkIndex = payload['chunkIndex'] as int;
    final totalChunks = payload['totalChunks'] as int;
    final dataB64 = payload['data'] as String;

    final encrypted = base64Url.decode(dataB64);
    // Find session from meta
    final meta = _incomingMeta[fileId];
    if (meta == null) return;

    // Decrypt chunk (using first available session for simplicity)
    Uint8List? decrypted;
    try {
      // session lookup would be done properly in production
      decrypted = encrypted; // placeholder — real impl uses encryption service
    } catch (e) {
      appLogger.e('Chunk decrypt failed', error: e);
      return;
    }

    if (_incomingChunks[fileId] == null) return;
    _incomingChunks[fileId]![chunkIndex] = decrypted;

    final received = _incomingChunks[fileId]!.where((c) => c != null).length;
    final fileName = meta['fileName'] as String;
    _emitProgress(
        fileId, fileName, totalChunks, received, FileTransferStatus.receiving);
  }

  Future<File?> _handleFileEnd(WebRTCMessage msg) async {
    final payload = msg.payload as Map<String, dynamic>;
    final fileId = payload['fileId'] as String;
    final meta = _incomingMeta[fileId];
    final chunks = _incomingChunks[fileId];
    if (meta == null || chunks == null) return null;

    final fileName = meta['fileName'] as String;
    final expectedHash = meta['fileHash'] as String;
    final totalChunks = meta['totalChunks'] as int;

    _emitProgress(fileId, fileName, totalChunks, totalChunks,
        FileTransferStatus.assembling);

    // Check all chunks received
    if (chunks.any((c) => c == null)) {
      appLogger.e('Missing chunks for file $fileId');
      _emitProgress(fileId, fileName, totalChunks, totalChunks,
          FileTransferStatus.failed);
      return null;
    }

    // Assemble
    final assembled = Uint8List.fromList(
        chunks.expand((c) => c!).toList());

    // Verify hash
    final actualHash = sha256.convert(assembled).toString();
    if (actualHash != expectedHash) {
      appLogger.e('Hash mismatch for file $fileId');
      _emitProgress(fileId, fileName, totalChunks, totalChunks,
          FileTransferStatus.failed);
      return null;
    }

    // Save to temp dir
    final tempDir = Directory.systemTemp;
    final outFile = File('${tempDir.path}/$fileId-$fileName');
    await outFile.writeAsBytes(assembled);

    _emitProgress(fileId, fileName, totalChunks, totalChunks,
        FileTransferStatus.complete);
    appLogger.i('File received & verified: $fileName');

    _incomingChunks.remove(fileId);
    _incomingMeta.remove(fileId);

    return outFile;
  }

  void _emitProgress(String fileId, String fileName, int total, int completed,
      FileTransferStatus status) {
    _progressController.add(FileTransferProgress(
      fileId: fileId,
      fileName: fileName,
      totalChunks: total,
      completedChunks: completed,
      status: status,
    ));
  }

  void dispose() {
    _progressController.close();
  }
}
