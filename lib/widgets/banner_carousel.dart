import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/net_image.dart';
import '../models/banner.dart' as m;

/// Auto-rotating promo banner carousel (reads from `banners` table).
class BannerCarousel extends StatefulWidget {
  final List<m.Banner> banners;
  const BannerCarousel({super.key, required this.banners});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return GestureDetector(
                onTap: () async {
                  final link = b.link;
                  if (link != null && link.isNotEmpty) {
                    // Normalize: shad:// -> https:// so external apps can open it
                    final normalized = link.startsWith('shad://')
                        ? link.replaceFirst('shad://', 'https://')
                        : link;
                    final uri = Uri.parse(normalized);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: NetImage(b.imageUrl, width: double.infinity, height: 150, radius: 14),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        if (widget.banners.length > 1)
          SmoothPageIndicator(
            controller: _controller,
            count: widget.banners.length,
            effect: const WormEffect(dotHeight: 8, dotWidth: 8, activeDotColor: Color(0xFF1DB954)),
          ),
      ],
    );
  }
}
