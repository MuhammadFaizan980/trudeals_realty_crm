import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:sizer/sizer.dart';

import 'src/core/di/injection.dart';
import 'src/core/network/mock_data.dart';
import 'src/core/theme/trudeals_theme.dart';
import 'src/features/auth/presentation/cubits/auth_cubit.dart';
import 'src/features/home/presentation/pages/home_page.dart';
import 'src/features/auth/presentation/pages/login_page.dart';
import 'src/features/automations/logic/automation_engine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('Initializing Hive...');
    await Hive.initFlutter();
    
    debugPrint('Initializing Mock Data...');
    await MockData.init();
    
    debugPrint('Initializing Dependencies...');
    await initializeDependencies();
    
    debugPrint('Starting Automation Engine...');
    getIt<AutomationEngine>().start();
    
    debugPrint('Initialization Complete. Running App.');
    runApp(const TruDealsApp());
  } catch (e, stack) {
    debugPrint('Fatal Initialization Error: $e');
    debugPrint('Stack Trace: $stack');
    runApp(MaterialApp(home: Scaffold(body: Center(child: Text('Fatal Error: $e')))));
  }
}

class TruDealsApp extends StatelessWidget {
  const TruDealsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'TruDeals Realty CRM',
          debugShowCheckedModeBanner: false,
          theme: TruDealsTheme.light,
          home: BlocProvider(
            create: (context) => getIt<AuthCubit>()..checkAuth(),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                debugPrint('Current AuthState: $state');
                if (state is Authenticated) {
                  return const HomePage();
                }
                if (state is AuthLoading) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Signing in...'),
                        ],
                      ),
                    ),
                  );
                }
                if (state is AuthError) {
                  return Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text('Error: ${state.message}', textAlign: TextAlign.center),
                          ),
                          ElevatedButton(
                            onPressed: () => context.read<AuthCubit>().checkAuth(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const LoginPage();
              },
            ),
          ),
        );
      },
    );
  }
}
