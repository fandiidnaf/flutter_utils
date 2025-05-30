import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_utils/theme/colors/app_theme.dart';
import 'package:flutter_utils/theme/const/app_const.dart';
import 'package:flutter_utils/theme/cubit/theme_cubit.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final box = await Hive.openBox(AppThemeConsts.themeBox);
  if (box.isEmpty) {
    await box.add('system');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(AppThemeConsts.themeBox);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeCubit(box.getAt(0).toString().toThemeMode),
        ),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, state) {
              state.changeSystemUi(context);

              return MaterialApp(
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: state,
                debugShowCheckedModeBanner: false,
                home: HomeScreen(selectedTheme: state),
              );
            },
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.selectedTheme});
  final ThemeMode selectedTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ThemeMode selectedTheme = widget.selectedTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldColor,
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please let us know your gender:'),
            ListTile(
              leading: Radio<ThemeMode>(
                value: ThemeMode.light,
                groupValue: selectedTheme,
                onChanged: (value) {
                  context.read<ThemeCubit>().changeTheme(value!);

                  setState(() {
                    selectedTheme = value;
                  });
                },
              ),
              title: const Text('Light'),
            ),
            ListTile(
              leading: Radio<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: selectedTheme,
                onChanged: (value) {
                  context.read<ThemeCubit>().changeTheme(value!);

                  setState(() {
                    selectedTheme = value;
                  });
                },
              ),
              title: const Text('Dark'),
            ),
            ListTile(
              leading: Radio<ThemeMode>(
                value: ThemeMode.system,
                groupValue: selectedTheme,
                onChanged: (value) {
                  context.read<ThemeCubit>().changeTheme(value!);
                  setState(() {
                    selectedTheme = value;
                  });
                },
              ),
              title: const Text('System'),
            ),
          ],
        ),
      ),
    );
  }
}
