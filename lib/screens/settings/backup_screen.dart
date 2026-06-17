import 'dart:developer' show log;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/backup_provider.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../config/app_config.dart';
import '../../utils/constants.dart';
import '../../utils/error_utils.dart';
import '../../utils/responsive.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  static const _autoBackupKey = 'auto_backup_enabled';
  bool _autoBackup = true;
  String _backupPath = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    const storage = FlutterSecureStorage();
    final autoBackup = await storage.read(key: _autoBackupKey);
    final dir = await getApplicationDocumentsDirectory();
    if (!mounted) return;
    setState(() {
      _autoBackup = autoBackup != 'false';
      _backupPath = dir.path;
    });
  }

  Future<void> _saveAutoBackupSetting(bool value) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _autoBackupKey, value: value.toString());
    if (mounted) setState(() => _autoBackup = value);
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final firebaseUser = ref.watch(firebaseAuthUserProvider);
    final isSignedIn = firebaseUser.hasValue && firebaseUser.value != null;
    final user = firebaseUser.hasValue ? firebaseUser.value : null;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Local Backup'),
                subtitle: const Text('Save database to device storage'),
                trailing: backupState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: backupState.isLoading
                    ? null
                    : () async {
                        try {
                          final dir = await getApplicationDocumentsDirectory();
                          final dbFile = File(
                            p.join(dir.path, kDbFileName),
                          );
                          final success = await ref
                              .read(backupNotifierProvider.notifier)
                              .localBackup(dbFile);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Backup saved locally'
                                    : 'Backup failed',
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            context.showError(e, source: 'backup');
                          }
                        }
                      },
              ),
              if (_backupPath.isNotEmpty) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _backupPath,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Local Restore'),
                subtitle: const Text('Restore from a local backup'),
                trailing: backupState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: backupState.isLoading
                    ? null
                    : () async {
                        try {
                          final restored = await ref
                              .read(backupNotifierProvider.notifier)
                              .localRestore();
                          if (!context.mounted) return;
                          if (restored) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Restore Complete'),
                                content: const Text(
                                  'Database restored from local backup. Please restart the app.',
                                ),
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
                              const SnackBar(
                                content: Text('No local backup found'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            context.showError(e, source: 'backup');
                          }
                        }
                      },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (AppConfig.isGoogleDriveConfigured)
          Card(
            child: Column(
              children: [
                if (isSignedIn && user != null) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoURL != null
                          ? NetworkImage(user.photoURL!)
                          : null,
                      child: user.photoURL == null
                          ? Text(
                              (user.displayName ?? user.email ?? '?')[0]
                                  .toUpperCase(),
                            )
                          : null,
                    ),
                    title: Text(user.displayName ?? user.email ?? 'Signed in'),
                    subtitle: Text(user.email ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await ref
                            .read(firebaseSignInProvider.notifier)
                            .signOut();
                      },
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(
                      Icons.cloud,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    title: const Text('Google Drive'),
                    subtitle: const Text('Sign in to enable cloud backup'),
                    trailing: const Icon(Icons.login),
                    onTap: () async {
                      try {
                        await ref
                            .read(firebaseSignInProvider.notifier)
                            .signInWithGoogle();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                  ),
                ],
                if (isSignedIn) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('Cloud Backup'),
                    subtitle: const Text('Backup to Google Drive'),
                    trailing: backupState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: backupState.isLoading
                        ? null
                        : () async {
                            try {
                              final dir =
                                  await getApplicationDocumentsDirectory();
                              final dbFile = File(
                                p.join(dir.path, kDbFileName),
                              );
                              final success = await ref
                                  .read(backupNotifierProvider.notifier)
                                  .backupDatabase(dbFile);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Backup completed'
                                        : 'Backup failed',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (context.mounted) {
                                context.showError(e, source: 'backup');
                              }
                            }
                          },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cloud_download),
                    title: const Text('Cloud Restore'),
                    subtitle: const Text('Restore from Google Drive'),
                    trailing: backupState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: backupState.isLoading
                        ? null
                        : () => _showCloudRestoreDialog(context),
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
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: isWide(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: body,
              ),
            )
          : body,
    );
  }

  void _showCloudRestoreDialog(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;
    List<Map<String, String>> backups;
    try {
      log('backup_ui: listing cloud backups...');
      backups = await ref
          .read(backupNotifierProvider.notifier)
          .listCloudBackups();
      log('backup_ui: found ${backups.length} backups');
    } catch (e) {
      if (context.mounted) context.showError(e, source: 'listCloudBackups');
      return;
    }
    if (!context.mounted) return;

    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No backups found on Google Drive')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cloud Backups'),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: backups.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final backup = backups[index];
              final name = backup['name'] ?? '';
              final createdTime = backup['createdTime'] ?? '';
              final isLatest = index == 0;

              DateTime? date;
              try {
                date = DateTime.parse(createdTime).toLocal();
              } catch (_) {}

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isLatest
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.cloud_download,
                    color: isLatest
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat(
                          'MMM d, yyyy • h:mm a',
                        ).format(date ?? DateTime.now()),
                        style: TextStyle(
                          fontWeight: isLatest
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isLatest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  log('backup_ui: restoring cloud backup ${backup['id']}...');
                  try {
                    final restored = await ref
                        .read(backupNotifierProvider.notifier)
                        .restoreCloudBackup(backup['id'] ?? '');
                    log('backup_ui: restore result=$restored');
                    if (!context.mounted) return;
                    if (restored) {
                      showDialog(
                        context: context,
                        builder: (ctx2) => AlertDialog(
                          title: const Text('Restore Complete'),
                          content: const Text(
                            'Database restored from cloud backup. Please restart the app.',
                          ),
                          actions: [
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(ctx2);
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Restore failed — check error log in Settings',
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    log('backup_ui: restore exception: $e');
                    if (context.mounted) {
                      context.showError(e, source: 'backup');
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
