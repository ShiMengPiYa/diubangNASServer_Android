import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/device_registry/device_label_constraints.dart';
import '../../../../core/profile/device_identity_store.dart';
import '../../domain/server_device_identity_service.dart';
import '../pages/device_avatar_crop_page.dart';

class ServerDeviceIdentityCard extends StatefulWidget {
  const ServerDeviceIdentityCard({super.key});

  @override
  State<ServerDeviceIdentityCard> createState() =>
      _ServerDeviceIdentityCardState();
}

class _ServerDeviceIdentityCardState extends State<ServerDeviceIdentityCard> {
  late final DeviceIdentityStore _identityStore;
  late final ServerDeviceIdentityService _identityService;

  String? _resolvedDisplayName;
  String? _avatarPath;
  int _avatarRevision = 0;
  String? _displayAlias;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _identityStore = DeviceIdentityStore(keyValueStore: ServiceLocator.keyValueStore);
    _identityService = ServiceLocator.serverDeviceIdentityService;
    _avatarPath = _identityStore.avatarPath;
    _displayAlias = _identityStore.displayAlias;
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final host = await _identityService.resolveHostDevice();
      await _identityService.syncFromHostRecord();
      final displayName = await _identityService.resolveUiDeviceName();
      if (!mounted) {
        return;
      }
      setState(() {
        _resolvedDisplayName = displayName;
        _displayAlias = _identityStore.displayAlias ?? host?.label;
        _applyAvatarFromStore();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
    }
  }

  void _applyAvatarFromStore() {
    _avatarPath = _identityStore.avatarPath;
    _avatarRevision =
        _identityStore.avatarUpdatedAt?.millisecondsSinceEpoch ?? 0;
  }

  Future<void> _evictAvatarCache(String path) async {
    await FileImage(File(path)).evict();
  }

  Future<void> _pickAvatar() async {
    try {
      final croppedBytes = await DeviceAvatarCropPage.pickAndCrop(context);
      if (croppedBytes == null || !mounted) {
        return;
      }

      await _identityService.setAvatarFromBytes(croppedBytes);
      if (!mounted) {
        return;
      }

      final savedPath = _identityStore.avatarPath;
      if (savedPath == null || savedPath.trim().isEmpty) {
        throw StateError('头像保存失败，请重试');
      }

      await _evictAvatarCache(savedPath);
      if (!mounted) {
        return;
      }
      setState(_applyAvatarFromStore);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('头像已更新')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('头像设置失败：$error')),
      );
    }
  }

  Future<void> _clearAvatar() async {
    try {
      final previousPath = _avatarPath;
      await _identityService.clearAvatar();
      if (!mounted) {
        return;
      }
      if (previousPath != null) {
        await _evictAvatarCache(previousPath);
      }
      setState(() {
        _avatarPath = null;
        _avatarRevision = 0;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清除头像失败：$error')),
      );
    }
  }

  Future<void> _editDisplayAlias() async {
    final alias = await showDialog<String?>(
      context: context,
      builder: (context) {
        return DisplayAliasDialog(initialAlias: _displayAlias);
      },
    );
    if (alias == null || !mounted) {
      return;
    }
    try {
      await _identityService.updateDisplayAlias(alias);
      if (!mounted) {
        return;
      }
      setState(() {
        _displayAlias = _identityStore.displayAlias;
        _resolvedDisplayName = null;
        _loading = true;
      });
      unawaited(_load());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('名称保存失败：$error')),
        );
      }
    }
  }

  Future<void> _showIdentityOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('设置头像'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAvatar();
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline),
                title: const Text('设置名称'),
                onTap: () {
                  Navigator.of(context).pop();
                  _editDisplayAlias();
                },
              ),
              if (_avatarPath != null)
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('恢复默认头像'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _clearAvatar();
                  },
                ),
              const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: _loading ? null : _showIdentityOptions,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                key: ValueKey('device-avatar-$_avatarPath-$_avatarRevision'),
                radius: 22,
                backgroundColor: AppTheme.successContainer,
                backgroundImage:
                    _avatarPath != null ? FileImage(File(_avatarPath!)) : null,
                child: _avatarPath == null
                    ? const Icon(Icons.dns_rounded, color: AppTheme.accentColor)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '设备身份',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightCardForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loading ? '加载中…' : (_resolvedDisplayName ?? '本机'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.lightSecondaryText),
            ],
          ),
        ),
      ),
    );
  }
}

class DisplayAliasDialog extends StatefulWidget {
  const DisplayAliasDialog({super.key, this.initialAlias});

  final String? initialAlias;

  @override
  State<DisplayAliasDialog> createState() => _DisplayAliasDialogState();
}

class _DisplayAliasDialogState extends State<DisplayAliasDialog> {
  late final TextEditingController _controller;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAlias ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final error = DeviceLabelConstraints.validate(_controller.text);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.settingsDialogTheme(context),
      child: AlertDialog(
        title: const Text('设置名称'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: DeviceLabelConstraints.maxLength,
          onChanged: (_) {
            if (_validationError != null) {
              setState(() => _validationError = null);
            }
          },
          decoration: InputDecoration(
            hintText: '例如：客厅 NAS',
            errorText: _validationError,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<String?>(null),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: _handleSave,
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

