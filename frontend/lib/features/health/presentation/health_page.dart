import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/providers/api_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ApiProvider>().checkHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final api = context.watch<ApiProvider>();
    final isHealthy = api.healthStatus == ApiStatus.success;
    final isError = api.healthStatus == ApiStatus.error;
    final isLoading = api.healthStatus == ApiStatus.loading;

    final statusColor = isHealthy
        ? AppColors.success
        : isError
        ? AppColors.error
        : AppColors.warning;

    final statusLabel = isLoading
        ? 'Checking…'
        : isHealthy
        ? 'Healthy'
        : 'Unreachable';

    return AppShell(
      currentRoute: '/health',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              icon: Icons.monitor_heart_rounded,
              title: 'System Status',
              subtitle: 'Monitor backend connectivity and API health',
            ),
            const SizedBox(height: 28),
            // Status Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation(statusColor),
                      ),
                    )
                  else
                    Icon(
                      isHealthy
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: statusColor,
                      size: 64,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: statusColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (api.lastHealthCheck != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last checked: ${_formatTime(api.lastHealthCheck!)}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (isError && api.healthError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      api.healthError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Metrics
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'LATENCY',
                    value: api.lastLatency != null
                        ? '${api.lastLatency!.inMilliseconds}ms'
                        : '–',
                    color:
                        api.lastLatency != null &&
                            api.lastLatency!.inMilliseconds < 200
                        ? AppColors.success
                        : AppColors.warning,
                    icon: Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: 'BACKEND',
                    value: AppConfig.backendUrl
                        .replaceFirst('http://', '')
                        .replaceFirst('https://', ''),
                    color: AppColors.info,
                    icon: Icons.cloud_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatTile(
                    label: 'ENV',
                    value: AppConfig.environment.toUpperCase(),
                    color: AppColors.primary,
                    icon: Icons.settings_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Refresh
            GradientButton(
              label: 'Refresh Status',
              icon: Icons.refresh_rounded,
              onPressed: isLoading ? null : () => api.checkHealth(),
              isLoading: isLoading,
            ),
            const SizedBox(height: 32),
            // API endpoints info
            SectionHeader(
              title: 'API Endpoints',
              icon: Icons.api_rounded,
              subtitle: 'Available HTTP/JSON endpoints',
            ),
            const SizedBox(height: 16),
            _EndpointCard(
              method: 'POST',
              path: '/pokereval.PokerEval/EvaluateHand',
              description: 'Evaluate best 5-card hand from 2+5 cards',
              example:
                  '{"hole_cards":["HA","SK"],"community_cards":["HQ","HJ","HT","D2","C3"]}',
            ),
            const SizedBox(height: 10),
            _EndpointCard(
              method: 'POST',
              path: '/pokereval.PokerEval/CompareHands',
              description: 'Compare two complete hands, returns winner',
              example:
                  '{"hole_cards_1":["HA","SK"],"community_cards_1":[...],"hole_cards_2":[...],"community_cards_2":[...]}',
            ),
            const SizedBox(height: 10),
            _EndpointCard(
              method: 'POST',
              path: '/pokereval.PokerEval/CalculateWinProbability',
              description: 'Monte Carlo win probability simulation',
              example:
                  '{"hole_cards":["HA","SA"],"community_cards":[],"num_players":2,"num_simulations":10000}',
            ),
            const SizedBox(height: 10),
            _EndpointCard(
              method: 'GET',
              path: '/healthz',
              description: 'Health check endpoint',
              example: '{"status":"ok","service":"pokereval"}',
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

class _EndpointCard extends StatefulWidget {
  final String method;
  final String path;
  final String description;
  final String example;

  const _EndpointCard({
    required this.method,
    required this.path,
    required this.description,
    required this.example,
  });

  @override
  _EndpointCardState createState() => _EndpointCardState();
}

class _EndpointCardState extends State<_EndpointCard> {
  bool _expanded = false;

  Color get _methodColor {
    switch (widget.method) {
      case 'GET':
        return AppColors.success;
      case 'POST':
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _methodColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.method,
                      style: TextStyle(
                        color: _methodColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.path,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Text(
                    widget.example,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
