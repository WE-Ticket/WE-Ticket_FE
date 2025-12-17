import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class DebugLogDialog extends StatefulWidget {
  final String title;
  final VoidCallback? onClose;

  const DebugLogDialog({
    super.key,
    this.title = 'Debug Logs',
    this.onClose,
  });

  @override
  State<DebugLogDialog> createState() => _DebugLogDialogState();
}

class _DebugLogDialogState extends State<DebugLogDialog> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // 새 로그가 추가될 때마다 자동 스크롤
    DebugLogManager.instance.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    DebugLogManager.instance.removeListener(_scrollToBottom);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // 로그 복사 버튼
                IconButton(
                  onPressed: _copyLogs,
                  icon: const Icon(Icons.copy, color: AppColors.white, size: 20),
                  tooltip: '로그 복사',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // 로그 클리어 버튼
                IconButton(
                  onPressed: _clearLogs,
                  icon: const Icon(Icons.clear_all, color: AppColors.white, size: 20),
                  tooltip: '로그 지우기',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // 닫기 버튼
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                  icon: const Icon(Icons.close, color: AppColors.white, size: 20),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 로그 목록
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.gray400),
                ),
                child: ListenableBuilder(
                  listenable: DebugLogManager.instance,
                  builder: (context, child) {
                    final logs = DebugLogManager.instance.logs;
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                // 타임스탬프
                                TextSpan(
                                  text: '[${log.timestamp}] ',
                                  style: const TextStyle(
                                    color: AppColors.gray400,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                // 로그 레벨
                                TextSpan(
                                  text: '${log.level.name.toUpperCase()}: ',
                                  style: TextStyle(
                                    color: _getLogLevelColor(log.level),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                // 메시지
                                TextSpan(
                                  text: log.message,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Live Debug Console',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: DebugLogManager.instance,
                    builder: (context, child) {
                      final logCount = DebugLogManager.instance.logs.length;
                      return Text(
                        '$logCount logs',
                        style: const TextStyle(
                          color: AppColors.gray400,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLogLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return AppColors.info;
      case LogLevel.warning:
        return AppColors.warning;
      case LogLevel.error:
        return AppColors.error;
      case LogLevel.success:
        return AppColors.success;
      case LogLevel.debug:
        return AppColors.gray400;
    }
  }

  void _copyLogs() {
    final logs = DebugLogManager.instance.logs;
    final logText = logs.map((log) => 
      '[${log.timestamp}] ${log.level.name.toUpperCase()}: ${log.message}'
    ).join('\n');
    
    Clipboard.setData(ClipboardData(text: logText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('로그가 클립보드에 복사되었습니다.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    DebugLogManager.instance.clearLogs();
  }
}

// 로그 데이터 클래스
class LogEntry {
  final String timestamp;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
  });
}

enum LogLevel {
  info,
  warning, 
  error,
  success,
  debug,
}

// 로그 관리자 (싱글톤)
class DebugLogManager extends ChangeNotifier {
  static final DebugLogManager _instance = DebugLogManager._internal();
  static DebugLogManager get instance => _instance;
  
  DebugLogManager._internal();

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => List.unmodifiable(_logs);

  void addLog(String message, {LogLevel level = LogLevel.info}) {
    final timestamp = DateTime.now().toString().substring(11, 23); // HH:mm:ss.SSS
    
    _logs.add(LogEntry(
      timestamp: timestamp,
      level: level,
      message: message,
    ));

    // 너무 많은 로그가 쌓이지 않도록 제한
    if (_logs.length > 500) {
      _logs.removeAt(0);
    }

    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // 편의 메서드들
  void info(String message) => addLog(message, level: LogLevel.info);
  void warning(String message) => addLog(message, level: LogLevel.warning);
  void error(String message) => addLog(message, level: LogLevel.error);
  void success(String message) => addLog(message, level: LogLevel.success);
  void debug(String message) => addLog(message, level: LogLevel.debug);
}