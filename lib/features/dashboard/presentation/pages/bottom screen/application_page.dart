// presentation/pages/bottom_screen/application_page.dart
import 'package:flutter/material.dart';


class ApplicationPage extends StatelessWidget {
  const ApplicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Page'),
      ),
      body: Center(
        child: Text(
          'This is the Application Page',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
