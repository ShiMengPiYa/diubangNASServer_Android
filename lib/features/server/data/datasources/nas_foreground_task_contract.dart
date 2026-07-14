// 文件输入：无
// 文件职责：集中定义前台任务与后台运行时之间共享的存储键和值
// 文件对外接口：NasForegroundTaskContract
// 文件包含：NasForegroundTaskContract

/// 输入：无
/// 职责：定义前台任务启动配置、运行状态和错误信息在插件存储中的键名
/// 对外接口：serverNameKey, serverIpKey, serverPortKey, runtimeStateKey, runtimeErrorKey
abstract final class NasForegroundTaskContract {
  static const String serverNameKey = 'diubang_nasserver.server_name';
  static const String serverIpKey = 'diubang_nasserver.server_ip';
  static const String serverPortKey = 'diubang_nasserver.server_port';
  static const String runtimeStateKey = 'diubang_nasserver.runtime_state';
  static const String runtimeErrorKey = 'diubang_nasserver.runtime_error';
  static const String presenceSnapshotKey = 'diubang_nasserver.presence_snapshot';

  static const String stateStarting = 'starting';
  static const String stateRunning = 'running';
  static const String stateStopped = 'stopped';
  static const String stateError = 'error';
}
