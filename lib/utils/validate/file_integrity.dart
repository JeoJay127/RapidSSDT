//  file_integrity.dart
//  Created by JeoJay127 
//
import 'dart:io';
import 'package:crypto/crypto.dart';

enum IntegrityAlgorithm { md5, sha1, sha256, sha512 }

class IntegrityResult {
  final bool valid;
  final IntegrityAlgorithm algorithm;

  const IntegrityResult({required this.valid, required this.algorithm});
}

class FileIntegrity {
  const FileIntegrity();
  
  /// 计算文件摘要（流式，支持大文件）
  Future<String> digestFile(
    File file, {
    IntegrityAlgorithm algorithm = IntegrityAlgorithm.sha256,
  }) async {
    if (!await file.exists()) {
      throw FileSystemException('File not found', file.path);
    }

    final hash = _resolveHash(algorithm);
    final digest = await hash.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<IntegrityResult> verifyFileWithResult(
    File file, {
    required String expectedDigest,
    IntegrityAlgorithm algorithm = IntegrityAlgorithm.sha256,
  }) async {
    final valid = await verifyFile(
      file,
      expectedDigest: expectedDigest,
      algorithm: algorithm,
    );

    return IntegrityResult(valid: valid, algorithm: algorithm);
  }

  /// 校验文件完整性
  Future<bool> verifyFile(
    File file, {
    required String expectedDigest,
    IntegrityAlgorithm algorithm = IntegrityAlgorithm.sha256,
  }) async {
    final actual = await digestFile(file, algorithm: algorithm);

    return _normalize(actual) == _normalize(expectedDigest);
  }

  Hash _resolveHash(IntegrityAlgorithm algorithm) {
    switch (algorithm) {
      case IntegrityAlgorithm.md5:
        return md5;
      case IntegrityAlgorithm.sha1:
        return sha1;
      case IntegrityAlgorithm.sha256:
        return sha256;
      case IntegrityAlgorithm.sha512:
        return sha512;
    }
  }

  String _normalize(String v) => v.trim().toLowerCase();
}
