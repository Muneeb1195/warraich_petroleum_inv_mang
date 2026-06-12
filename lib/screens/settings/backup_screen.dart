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
  bool _autoBackup = true;

  @override
  void initState() {
    super.initState();
    _loadAutoBackupSetting();
  }

  Future<void> _loadAutoBackupSetting() async {
    const storage = FlutterSecureStorage();
    final value = await storage.read(key: _autoBackupKey);
    setState(() => _autoBackup = value != 'false');
  }

  Future<void> _saveAutoBackupSetting(bool value) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _autoBackupKey, value: value.toString());
    setState(() => _autoBackup = value);
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Google Drive Backup',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data is backed up to Google Drive. Maximum 5 backups are retained.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Manual Backup'),
                  subtitle: const Text('Backup now to Google Drive'),
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
                  title: const Text('Restore from Backup'),
                  subtitle: const Text('Restore database from Google Drive'),
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
                                content: const Text('Database restored. Please restart the app for changes to take effect.'),
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
                  subtitle: const Text('Daily automatic backup to Google Drive'),
                  value: _autoBackup,
                  onChanged: (value) => _saveAutoBackupSetting(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
