/// 文件输入：AppRouter, AppTheme, ServiceLocator
/// 文件职责：定义 MaterialApp 根组件，配置路由和主题
/// 文件对外接口：NasServerApp
/// 文件包含：NasServerApp
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'di/service_locator.dart';
import '../features/server/presentation/cubit/server_cubit.dart';

class NasServerApp extends StatefulWidget {
  const NasServerApp({super.key});

  @override
  State<NasServerApp> createState() => _NasServerAppState();
}

class _NasServerAppState extends State<NasServerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ServiceLocator.releaseMdnsOnAppExit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServerCubitImpl>(
      create: (_) => ServiceLocator.serverCubit,
      child: MaterialApp(
        title: '铥棒文件S',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        initialRoute: '/',
        onGenerateRoute: const AppRouter().generateRoute,
      ),
    );
  }
}
