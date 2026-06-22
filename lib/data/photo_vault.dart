/// Encrypted photo storage.
///
/// Each frame's JPEG bytes are written to the app documents dir under
/// [dirName], encrypted with AES-256-GCM. The key is generated once on first
/// use and stored in [FlutterSecureStorage] (backed by Android Keystore).
///
/// This is the single isolation point for at-rest encryption: if the crypto
/// stack ever breaks a build, swap the read/write bodies for plaintext and
/// the rest of the app is unaffected.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoVault {
  PhotoVault._();
  static final PhotoVault instance = PhotoVault._();

  static const _dirName = 'photos';
  static const _keyStorageKey = 'reframe_vault_key_v1';

  final FlutterSecureStorage _secure = const FlutterSecureStorage();
  SecretKey? _key;
  final _algo = AesGcm.with256bits();

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, _dirName));
    if (!d.existsSync()) d.createSync(recursive: true);
    return d;
  }

  Future<SecretKey> _loadKey() async {
    if (_key != null) return _key!;
    final existing = await _secure.read(key: _keyStorageKey);
    if (existing != null) {
      _key = SecretKey(Uint8List.fromList(base64.decode(existing)));
    } else {
      final sk = await _algo.newSecretKey();
      final bytes = await sk.extractBytes();
      _key = SecretKey(bytes);
      await _secure.write(key: _keyStorageKey, value: base64.encode(bytes));
    }
    return _key!;
  }

  /// Encrypts [bytes] and writes them to a file named [fileName] in the vault.
  /// Returns the file name (so callers store only that in the DB).
  Future<String> write(String fileName, Uint8List bytes) async {
    final key = await _loadKey();
    final secret = await key.extractBytes();
    final nonce = _algo.newNonce();
    final box = await _algo.encrypt(
      bytes,
      secretKey: SecretKey(secret),
      nonce: nonce,
    );
    // File layout: [12-byte nonce][16-byte mac][ciphertext]
    final mac = box.mac.bytes;
    final out = Uint8List(nonce.length + mac.length + box.cipherText.length);
    out.setRange(0, nonce.length, nonce);
    out.setRange(nonce.length, nonce.length + mac.length, mac);
    out.setRange(nonce.length + mac.length, out.length, box.cipherText);
    final dir = await _dir();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(out, flush: true);
    return fileName;
  }

  /// Reads and decrypts the file named [fileName]; returns raw JPEG bytes.
  Future<Uint8List> read(String fileName) async {
    final key = await _loadKey();
    final secret = await key.extractBytes();
    final dir = await _dir();
    final file = File(p.join(dir.path, fileName));
    final blob = await file.readAsBytes();
    final nonce = blob.sublist(0, 12);
    final mac = blob.sublist(12, 28);
    final cipherText = blob.sublist(28);
    final box = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(mac),
    );
    final plain = await _algo.decrypt(
      box,
      secretKey: SecretKey(secret),
    );
    return Uint8List.fromList(plain);
  }

  /// Permanently deletes a frame file (no-op if it's already gone).
  Future<void> delete(String fileName) async {
    final dir = await _dir();
    final file = File(p.join(dir.path, fileName));
    if (file.existsSync()) await file.delete();
  }
}