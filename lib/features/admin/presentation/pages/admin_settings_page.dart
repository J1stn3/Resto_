import 'package:flutter/material.dart';
import '../../../../config/app_config.dart';
import '../../../../config/theme.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/settings/app_settings.dart';
import '../../../../core/widgets/app_ui.dart';
import '../../../../core/widgets/responsive.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final _settings = sl<AppSettings>();
  late final TextEditingController _restaurantName;
  late double _taxRate;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _restaurantName = TextEditingController(text: _settings.restaurantName);
    _taxRate = _settings.taxRate;
    _themeMode = _settings.themeMode;
  }

  @override
  void dispose() {
    _restaurantName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _settings.save(
      restaurantName: _restaurantName.text.trim(),
      taxRate: _taxRate,
      themeMode: _themeMode,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved'), backgroundColor: AppTheme.accent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppBreakpoints.pagePadding(context),
      children: [
        const PageSectionTitle('Settings', subtitle: 'Restaurant preferences and appearance'),
        const SizedBox(height: 20),
        SettingsSectionCard(
          title: 'Restaurant',
          icon: Icons.storefront_rounded,
          children: [
            TextField(
              controller: _restaurantName,
              decoration: const InputDecoration(labelText: 'Restaurant name', prefixIcon: Icon(Icons.badge_outlined)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          title: 'Financial',
          icon: Icons.account_balance_wallet_outlined,
          children: [
            Text(
              'Tax rate: ${(_taxRate * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text('Applied to new orders in POS', style: Theme.of(context).textTheme.bodySmall),
            Slider(
              value: _taxRate,
              min: 0,
              max: 0.25,
              divisions: 25,
              label: '${(_taxRate * 100).toStringAsFixed(0)}%',
              onChanged: (v) => setState(() => _taxRate = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsSectionCard(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
              ],
              selected: {_themeMode},
              onSelectionChanged: (s) => setState(() => _themeMode = s.first),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Settings'),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.link_rounded, color: AppTheme.primary, size: 20),
            ),
            title: const Text('API endpoint'),
            subtitle: Text(AppConfig.apiBaseUrl, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
