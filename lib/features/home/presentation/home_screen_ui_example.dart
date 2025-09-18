import 'package:dishcovery_app/features/examples/camera_test_screen.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/theme_switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          // Theme switcher button - menggunakan widget yang reusable
          const ThemeSwitcher(),
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
                text: 'Test Camera',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CameraExampleScreen(),
                    ),
                  );
                },
                type: ButtonType.secondary,
              ),
              SizedBox(height: 16),
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
