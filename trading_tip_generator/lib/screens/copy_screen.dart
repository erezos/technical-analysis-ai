import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_logger.dart';

class CopyScreen extends StatefulWidget {
  const CopyScreen({super.key});

  @override
  State<CopyScreen> createState() => _CopyScreenState();
}

class _CopyScreenState extends State<CopyScreen> {
  late final WebViewController _controller;
  // Changed to 250x600 for better mobile fullscreen experience
  final String _zuluTradeUrl = 'https://www.zulutrade.com/widgets/carousel?Lang=en&ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=DynamicWidget250x600&theme=dark&size=20';
  
  @override
  void initState() {
    super.initState();
    // Log page view event
    _logPageView();
    
    // Initialize WebView controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // Log when widget starts loading
            AppLogger.info('📊 [ANALYTICS] Copy widget loading: $url');
            FirebaseAnalytics.instance.logEvent(
              name: 'copy_widget_loading',
              parameters: {
                'url': url,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
          },
          onPageFinished: (String url) {
            // Log when widget finishes loading
            AppLogger.info('📊 [ANALYTICS] Copy widget loaded: $url');
            FirebaseAnalytics.instance.logEvent(
              name: 'copy_widget_loaded',
              parameters: {
                'url': url,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
          },
          onWebResourceError: (WebResourceError error) {
            // Log widget loading errors
            FirebaseAnalytics.instance.logEvent(
              name: 'copy_widget_error',
              parameters: {
                'error': error.description,
                'error_code': error.errorCode,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            
            // Handle app store and market:// redirects
            if (url.startsWith('market://') || 
                url.startsWith('https://play.google.com/') ||
                url.startsWith('https://apps.apple.com/') ||
                url.contains('zulu.trade.app')) {
              
              // Log the redirect attempt
              AppLogger.info('📊 [ANALYTICS] Copy widget app redirect: $url');
              FirebaseAnalytics.instance.logEvent(
                name: 'copy_widget_app_redirect',
                parameters: {
                  'destination_url': url,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                },
              );
              
              // Launch in external app/browser
              _launchExternalUrl(url);
              return NavigationDecision.prevent;
            }
            
            // Handle ZuluTrade registration/login pages
            if (url.contains('zulutrade.com') && 
                (url.contains('register') || url.contains('login') || url.contains('signup'))) {
              
              // Log successful navigation to ZuluTrade
              FirebaseAnalytics.instance.logEvent(
                name: 'copy_widget_zulutrade_navigation',
                parameters: {
                  'destination_url': url,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                },
              );
              
              // Launch in external browser for better experience
              _launchExternalUrl(url);
              return NavigationDecision.prevent;
            }
            
            // Allow other navigation within the widget
            FirebaseAnalytics.instance.logEvent(
              name: 'copy_widget_navigation',
              parameters: {
                'destination_url': url,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              },
            );
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_zuluTradeUrl));
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      // Convert market:// URLs to proper app store URLs while preserving referral parameters
      String targetUrl = url;
      if (url.startsWith('market://details?id=')) {
        // Extract the full query string to preserve all parameters including referrer
        final uri = Uri.parse(url);
        final appId = uri.queryParameters['id'];
        if (appId != null) {
          // Build Play Store URL with all original parameters
          final queryParams = Map<String, String>.from(uri.queryParameters);
          final playStoreUri = Uri.https('play.google.com', '/store/apps/details', queryParams);
          targetUrl = playStoreUri.toString();
        }
      }
      
      final uri = Uri.parse(targetUrl);
      
      // Try to launch the URL directly - Android WebView sometimes has issues with canLaunchUrl
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Log successful external launch
        AppLogger.info('📊 [ANALYTICS] Copy widget external launch success: $targetUrl');
        FirebaseAnalytics.instance.logEvent(
          name: 'copy_widget_external_launch_success',
          parameters: {
            'original_url': url,
            'launch_url': targetUrl,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (launchError) {
        AppLogger.info('📊 [ANALYTICS] Direct launch failed, trying alternative method: $launchError');
        // Fallback: try with platformDefault mode
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          AppLogger.info('📊 [ANALYTICS] Copy widget external launch success (fallback): $targetUrl');
          FirebaseAnalytics.instance.logEvent(
            name: 'copy_widget_external_launch_success',
            parameters: {
              'original_url': url,
              'launch_url': targetUrl,
              'method': 'fallback',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            },
          );
        } catch (fallbackError) {
          AppLogger.error('📊 [ANALYTICS] All launch methods failed: $fallbackError');
          throw Exception('Cannot launch URL: $targetUrl - $fallbackError');
        }
      }
    } catch (e) {
      // Log failed external launch
      AppLogger.error('📊 [ANALYTICS] Copy widget external launch failed: $url - Error: $e');
      FirebaseAnalytics.instance.logEvent(
        name: 'copy_widget_external_launch_failed',
        parameters: {
          'url': url,
          'error': e.toString(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open external link'),
            backgroundColor: const Color(0xFFFF9800),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _launchExternalUrl(url),
            ),
          ),
        );
      }
    }
  }

  void _logPageView() {
    AppLogger.info('📊 [ANALYTICS] Copy screen view logged');
    FirebaseAnalytics.instance.logEvent(
      name: 'copy_screen_view',
      parameters: {
        'screen_name': 'copy_screen',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void _logWidgetInteraction() {
    FirebaseAnalytics.instance.logEvent(
      name: 'copy_widget_interaction',
      parameters: {
        'widget_type': 'zulutrade_carousel',
        'url': _zuluTradeUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  void _openZuluTradeWithReferral() {
    // Open ZuluTrade with referral ID directly
    const referralUrl = 'https://www.zulutrade.com/?ref=2915819&utm_source=2915819&utm_medium=affiliate&utm_campaign=widget_click';
    AppLogger.info('📊 [ANALYTICS] Attempting to open ZuluTrade with referral URL: $referralUrl');
    _launchExternalUrl(referralUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      // Match trading tip screens' AppBar design exactly
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          automaticallyImplyLeading: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0F13), Color(0xFF16222A), Color(0xFF0F2027), Color(0xFF2C5364), Color(0xFF00373A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.supervisor_account,
                size: 24,
                color: Color(0xFF00F0C8),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'COPY TRADERS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: MediaQuery.of(context).size.width < 350 ? 16 : 22,
                    letterSpacing: 1.1,
                    color: const Color(0xFF00F0C8),
                    shadows: const [
                      Shadow(
                        blurRadius: 16,
                        color: Color(0xFF00F0C8),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color.fromRGBO(216, 221, 230, 1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // The WebView widget
                    WebViewWidget(
                      controller: _controller,
                    ),
                    
                    // Clickable overlay that covers most of the widget
                    // but excludes the scroll arrows (left and right edges)
                    Positioned.fill(
                      child: Row(
                        children: [
                          // Left scroll arrow area (not clickable)
                          const SizedBox(width: 50),
                          
                          // Main clickable area
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                AppLogger.info('📊 [ANALYTICS] Copy widget clicked - opening ZuluTrade with referral');
                                _logWidgetInteraction();
                                _openZuluTradeWithReferral();
                              },
                              child: Container(
                                color: Colors.transparent,
                                // Invisible clickable area
                              ),
                            ),
                          ),
                          
                          // Right scroll arrow area (not clickable)
                          const SizedBox(width: 50),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 