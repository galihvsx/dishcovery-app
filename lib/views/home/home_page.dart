import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dishcovery',
        actions: [
          // Theme switcher button
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              final themeProvider = context.read<ThemeProvider>();
              final currentTheme = Theme.of(context).brightness;
              themeProvider.setThemeMode(
                currentTheme == Brightness.light
                    ? ThemeMode.dark
                    : ThemeMode.light,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Shared Widgets Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              // Text Fields Section
              const Text(
                'Text Fields',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Basic Input',
                hint: 'Type something...',
                controller: _textController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password Input',
                hint: 'Enter password',
                obscureText: true,
                suffixIcon: const Icon(Icons.visibility),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Search Input',
                hint: 'Search...',
                prefixIcon: const Icon(Icons.search),
              ),
              const SizedBox(height: 32),

              // Buttons Section
              const Text(
                'Buttons',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Primary Button',
                onPressed: () {},
                type: ButtonType.primary,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Secondary Button',
                onPressed: () {},
                type: ButtonType.secondary,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Outline Button',
                onPressed: () {},
                type: ButtonType.outline,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Button with Icon',
                onPressed: () {},
                icon: Icons.add,
                type: ButtonType.primary,
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Loading Button',
                onPressed: null,
                isLoading: true,
                type: ButtonType.primary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Left',
                      onPressed: () {},
                      type: ButtonType.outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Right',
                      onPressed: () {},
                      type: ButtonType.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
