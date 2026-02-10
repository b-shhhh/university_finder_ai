import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:Uniguide/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:Uniguide/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('AuthProvider provides AuthViewModel', (tester) async {
    await tester.pumpWidget(
      AuthProvider(
        child: Builder(
          builder: (context) {
            final vm = Provider.of<AuthViewModel>(context);
            expect(vm, isA<AuthViewModel>());
            return Container();
          },
        ),
      ),
    );
  });
}
