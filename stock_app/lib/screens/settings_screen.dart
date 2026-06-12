import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _thresholdController = TextEditingController();
  final _wooUrlController = TextEditingController();
  final _wooKeyController = TextEditingController();
  final _wooSecretController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getInt('low_stock_threshold') ?? 5;
    
    _thresholdController.text = threshold.toString();
    _wooUrlController.text = prefs.getString('woo_url') ?? '';
    _wooKeyController.text = prefs.getString('woo_key') ?? '';
    _wooSecretController.text = prefs.getString('woo_secret') ?? '';
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final threshold = int.tryParse(_thresholdController.text) ?? 5;
    await prefs.setInt('low_stock_threshold', threshold);
    ref.read(lowStockThresholdProvider.notifier).state = threshold;

    await prefs.setString('woo_url', _wooUrlController.text.trim());
    await prefs.setString('woo_key', _wooKeyController.text.trim());
    await prefs.setString('woo_secret', _wooSecretController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    _wooUrlController.dispose();
    _wooKeyController.dispose();
    _wooSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('General', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Low Stock Alert Threshold',
              helperText: 'Products below this quantity will appear in alerts',
            ),
          ),
          
          const SizedBox(height: 32),
          Text('WooCommerce Sync', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _wooUrlController,
            decoration: const InputDecoration(
              labelText: 'Store URL',
              hintText: 'https://your-store.com',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _wooKeyController,
            decoration: const InputDecoration(
              labelText: 'Consumer Key',
              hintText: 'ck_...',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _wooSecretController,
            decoration: const InputDecoration(
              labelText: 'Consumer Secret',
              hintText: 'cs_...',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 32),
          
          ElevatedButton(
            onPressed: _saveSettings,
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }
}
