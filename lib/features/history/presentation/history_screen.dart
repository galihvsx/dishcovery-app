import 'dart:io';
import 'package:dishcovery_app/features/result/presentation/result_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dishcovery_app/core/widgets/custom_app_bar.dart';
import 'package:dishcovery_app/core/widgets/theme_switcher.dart';
import 'package:dishcovery_app/core/models/scan_model.dart';
import 'package:dishcovery_app/providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  static const String path = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _refreshHistory(BuildContext context) async {
    await Provider.of<HistoryProvider>(context, listen: false).loadHistory();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HistoryProvider>(context, listen: false).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
          title: 'history_screen.title'.tr(), actions: const [ThemeSwitcher()]),
      body: RefreshIndicator(
        onRefresh: () => _refreshHistory(context),
        child: Consumer<HistoryProvider>(
          builder: (context, provider, child) {
            final history = provider.historyList;

            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'history_screen.empty_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'history_screen.empty_subtitle'.tr(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final ScanResult item = history[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: item.imagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: Image.file(
                              File(item.imagePath),
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const CircleAvatar(
                            radius: 28,
                            child: Icon(Icons.fastfood),
                          ),
                    title: Text(
                      item.name.isNotEmpty
                          ? item.name
                          : 'history_screen.unknown_dish'.tr(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      item.description.isNotEmpty
                          ? item.description
                          : 'history_screen.no_description'.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('history_screen.delete_dialog_title'.tr()),
                            content: Text(
                              'history_screen.delete_dialog_content'.tr(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('common.cancel'.tr()),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await provider.deleteHistory(item.id!);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'history_screen.snackbar_deleted'.tr()),
                                    ),
                                  );
                                },
                                child: Text(
                                  'common.delete'.tr(),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResultScreen(initialData: item),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('history_screen.snackbar_add'.tr())));
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}