import 'package:blog_app/l10n/app_localizations.dart';
import 'package:blog_app/routing/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  final PageController _controller = PageController();

  final ValueNotifier<int> _currentPage = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isFirstLaunch', false);
    });
    _controller.addListener(() {
      _currentPage.value = _controller.page?.round() ?? 0;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final List<String> pages = [
      loc.welcome,
      loc.readBlogs,
      loc.writePublish,
      loc.saveFavorites,
      loc.shareWorld,
      loc.getStarted,
    ];
    final height = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                itemBuilder: (_, index) => Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      pages[index],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

            // Smooth Page Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: SmoothPageIndicator(
                controller: _controller,
                count: pages.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.black,
                  dotColor: Colors.grey,
                  dotHeight: 10,
                  dotWidth: 10,
                  spacing: 8,
                  expansionFactor: 3,
                ),
              ),
            ),

            // Navigation Button
            ValueListenableBuilder<int>(
              valueListenable: _currentPage,
              builder: (context, pageIndex, _) {
                final isLastPage = pageIndex == pages.length - 1;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: height * 0.05,
                    left: 24,
                    right: 24,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        if (isLastPage) {
                          GoRouter.of(context).pushNamed(Routes.login);
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(isLastPage ? loc.getStarted : loc.next),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
