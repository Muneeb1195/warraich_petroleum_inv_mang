import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/backup_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  static const _autoBackupKey = 'auto_backup_enabled';
  static const _signedInKey = 'google_signed_in';
  bool _autoBackup = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    const storage = FlutterSecureStorage();
    final autoBackup = await storage.read(key: _autoBackupKey);
    final signedIn = await storage.read(key: _signedInKey);
    setState(() {
      _autoBackup = autoBackup != 'false';
      _isSignedIn = signedIn == 'true';
    });
  }

  Future<void> _saveAutoBackupSetting(bool value) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _autoBackupKey, value: value.toString());
    setState(() => _autoBackup = value);
  }

  Future<void> _toggleSignIn() async {
    const storage = FlutterSecureStorage();
    if (_isSignedIn) {
      await ref.read(backupNotifierProvider.notifier).signOut();
      await storage.write(key: _signedInKey, value: 'false');
      setState(() => _isSignedIn = false);
    } else {
      final success = await ref.read(backupNotifierProvider.notifier).signIn();
      if (success) {
        await storage.write(key: _signedInKey, value: 'true');
        setState(() => _isSignedIn = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: const Text('Local Backup'),
                  subtitle: const Text('Save database to Downloads'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final dir = await getApplicationDocumentsDirectory();
                    final dbFile = File(p.join(dir.path, 'warraich_petroleum.db'));
                    final downloadsDir = Directory('/storage/emulated/0/Download');
                    if (await downloadsDir.exists()) {
                      final backupFile = File(p.join(downloadsDir.path, 'warraich_petroleum_backup.db'));
                      await dbFile.copy(backupFile.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Backup saved to Downloads')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Local Restore'),
                  subtitle: const Text('Restore from Downloads folder'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final backupFile = File('/storage/emulated/0/Download/warraich_petroleum_backup.db');
                    if (await backupFile.exists()) {
                      final dir = await getApplicationDocumentsDirectory();
                      final dbFile = File(p.join(dir.path, 'warraich_petroleum.db'));
                      await backupFile.copy(dbFile.path);
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Restore Complete'),
                            content: const Text('Database restored. Please restart the app.'),
                            actions: [
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  Navigator.pop(context);
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No backup file found in Downloads')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud, color: _isSignedIn ? colorScheme.primary : colorScheme.onSurfaceVariant),
                  title: Text(_isSignedIn ? 'Signed in to Google' : 'Google Drive'),
                  subtitle: Text(_isSignedIn ? 'Connected to Google Drive' : 'Sign in to enable cloud backup'),
                  trailing: Switch(value: _isSignedIn, onChanged: (_) => _toggleSignIn()),
                ),
                if (_isSignedIn) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.backup),
                    title: const Text('Cloud Backup'),
                    subtitle: const Text('Backup to Google Drive'),
                    trailing: backupState.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right),
                    onTap: backupState.isLoading
                        ? null
                        : () async {
                            final dir = await getApplicationDocumentsDirectory();
                            final dbFile = File(p.join(dir.path, 'warraich_petroleum.db'));
                            final success = await ref.read(backupNotifierProvider.notifier).backupDatabase(dbFile);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(success ? 'Backup completed' : 'Backup failed')),
                            );
                          },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.restore),
                    title: const Text('Cloud Restore'),
                    subtitle: const Text('Restore from Google Drive'),
                    trailing: backupState.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.chevron_right),
                    onTap: backupState.isLoading
                        ? null
                        : () async {
                            final dir = await getApplicationDocumentsDirectory();
                            final dbFile = File(p.join(dir.path, 'warraich_petroleum.db'));
                            final restored = await ref.read(backupNotifierProvider.notifier).restoreFromDrive(dbFile);
                            if (!context.mounted) return;
                            if (restored) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Restore Complete'),
                                  content: const Text('Database restored. Please restart the app.'),
                                  actions: [
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No backup found or restore failed')),
                              );
                            }
                          },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.sync),
                    title: const Text('Auto Backup'),
                    subtitle: const Text('Daily automatic backup'),
                    value: _autoBackup,
                    onChanged: (value) => _saveAutoBackupSetting(value),
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
