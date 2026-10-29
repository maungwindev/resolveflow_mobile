import 'package:resolveflow/src/imports/core_imports.dart';
import 'package:resolveflow/src/imports/packages_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Widget current = _buildCupertinoApp(context);
    current = AppPlatformScope(
      style: AppPlatformStyle.cupertino,
      child: current,
    );
    return ScreenUtilWrapper(child: current);
  }


  Widget _buildCupertinoApp(BuildContext context) {
    return GetCupertinoApp(
      initialBinding: AppBindings(),
      title: 'resolveflow',
      debugShowCheckedModeBanner: false,
      theme: buildCupertinoTheme(primaryColorHex: '#4F772D'),
      initialRoute: AppRoutes.onboarding,
      getPages: AppRouter.getPages,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        current = SessionListenerWrapper(child: current);

        // Ensure Material themes (tokens, widget styles like dialogs/buttons/inputs)
        // are available even in Cupertino mode, as many apps use a mix of both.
        current = Theme(
          data: (MediaQuery.of(context).platformBrightness == Brightness.dark)
              ? buildDarkTheme(primaryColorHex: '#4F772D')
              : buildLightTheme(primaryColorHex: '#4F772D'),
          child: current,
        );

        return current;
      },
    );
  }
}
