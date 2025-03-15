import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:store_management/screens/check_sheet_products_screen/core/check_expires/check_expires_cubit.dart';
import '/screens/auth_screen/repository/auth_repostory.dart';
import '/screens/check_sheet_products_screen/core/check_sheet/check_sheet_cubit.dart';
import '/screens/check_sheet_products_screen/core/detail_bloc/product_bloc.dart';
import '/screens/check_sheet_products_screen/core/search_products/search_products_cubit.dart';
import '/screens/check_sheet_products_screen/repository/check_sheet_repository.dart';
import '/screens/check_sheet_products_screen/repository/product_repository.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/route_settings.dart';
import 'constants/contains.dart';
import 'screens/auth_screen/core/auth_bloc.dart';
import 'screens/screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);


  //rotate the screen
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);



  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint(e.toString());
  }
  setPathUrlStrategy();
  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     builder: (context) => const StoreManagementApp(), // Wrap your app
  //   ),
  // );
  runApp(const StoreManagementApp());
  // runApp(
  //   DevicePreview(
  //     enabled: !kReleaseMode,
  //     // tools: const [
  //     //   ...DevicePreview.defaultTools,
  //     // ],
  //     child: const StoreManagementApp(),
  //   ),
  // );
}

class StoreManagementApp extends StatefulWidget {
  const StoreManagementApp({Key? key}) : super(key: key);

  @override
  State<StoreManagementApp> createState() => _StoreManagementAppState();
}

class _StoreManagementAppState extends State<StoreManagementApp> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      void _showToast(String message) {
        Fluttertoast.showToast(
          msg: message,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      if (results.contains(ConnectivityResult.none)) {
        _showToast('Không có kết nối mạng');
        _timer = Timer.periodic(const Duration(seconds: 5),
                (t) => _showToast('Không có kết nối mạng'));
      } else {
        Fluttertoast.showToast(
            msg: 'Kết nối thành công',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
        _timer?.cancel();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(AuthRepository())..add(CheckLoginEvent()),
        ),
        BlocProvider(
          create: (context) =>
              ProductBloc(ProductRepository(), CheckSheetRepository()),
        ),
        BlocProvider(
          create: (context) => SearchProductsCubit(ProductRepository()),
        ),
        BlocProvider(
          create: (context) => CheckExpiresCubit(ProductRepository()),
        ),
        BlocProvider(
          create: (context) => CheckSheetCubit(CheckSheetRepository()),
        ),
      ],
      child: GetMaterialApp(
        title: 'Tồn kho KiotLix',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          primarySwatch: MaterialColor(kPrimaryColor.value, kPrimaryColorMap),
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: GoogleFonts.openSans().fontFamily,
                bodyColor: kTextColor,
              ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData.dark(),
        initialRoute: CheckingLoginPage.routeName,
        onGenerateRoute: RouteSettingsWithArguments.generateRoute,
      ),
    );
  }
}
