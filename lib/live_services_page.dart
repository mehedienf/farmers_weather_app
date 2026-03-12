import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/disaster_app_bar.dart';
import 'widgets/web_view_page.dart';

class LiveServicesPage extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const LiveServicesPage({super.key, this.onMenuTap});

  static const _services = [
    _Service(
      category: 'আবহাওয়া ও দুর্যোগ',
      openInWebView: true,
      items: [
        _ServiceItem(
          title: 'BMD আবহাওয়া পূর্বাভাস',
          subtitle: 'Bangladesh Meteorological Department',
          icon: Icons.wb_cloudy_rounded,
          color: Color(0xFF0284C7),
          url: 'https://www.bmd.gov.bd/',
        ),
        _ServiceItem(
          title: 'FFWC বন্যা মানচিত্র',
          subtitle: 'Flood Forecasting & Warning Centre — live map',
          icon: Icons.water_rounded,
          color: Color(0xFF0369A1),
          url: 'https://www.ffwc.gov.bd/app/flood-magnitude',
        ),
        _ServiceItem(
          title: 'Google Flood Map — বাংলাদেশ',
          subtitle: 'Google Flood Forecasting Initiative',
          icon: Icons.map_rounded,
          color: Color(0xFF1A73E8),
          url:
              'https://sites.research.google/floods/l/23.957665118872956/91.42051660416591/6.789099225431683',
        ),
        _ServiceItem(
          title: 'DDM দুর্যোগ ব্যবস্থাপনা',
          subtitle: 'Dept. of Disaster Management',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFB45309),
          url: 'https://www.ddm.gov.bd/',
        ),
      ],
    ),
    _Service(
      category: 'কৃষি বাজার',
      openInWebView: false,
      items: [
        _ServiceItem(
          title: 'DAM দৈনিক বাজার মূল্য',
          subtitle: 'কৃষি বিপণন অধিদপ্তর',
          icon: Icons.storefront_rounded,
          color: Color(0xFF16A34A),
          url:
              'https://www.dam.gov.bd/index.php/price-report/daily-market-price',
        ),
        _ServiceItem(
          title: 'BAMIS কৃষি উপদেষ্টা',
          subtitle: 'Bangladesh Agrometeorological Info.',
          icon: Icons.agriculture_rounded,
          color: Color(0xFF15803D),
          url: 'https://www.bamis.gov.bd/',
        ),
        _ServiceItem(
          title: 'BARC কৃষি গবেষণা',
          subtitle: 'Bangladesh Agricultural Research Council',
          icon: Icons.science_rounded,
          color: Color(0xFF166534),
          url: 'https://www.barc.gov.bd/',
        ),
      ],
    ),
    _Service(
      category: 'কৃষি সেবা ও ঋণ',
      openInWebView: false,
      items: [
        _ServiceItem(
          title: 'BADC বীজ ও সেচ',
          subtitle: 'Bangladesh Agricultural Development Corp.',
          icon: Icons.local_florist_rounded,
          color: Color(0xFF7C3AED),
          url: 'https://www.badc.gov.bd/',
        ),
        _ServiceItem(
          title: 'BKB কৃষি ব্যাংক',
          subtitle: 'Bangladesh Krishi Bank — কৃষি ঋণ',
          icon: Icons.account_balance_rounded,
          color: Color(0xFFB45309),
          url: 'https://www.krishibank.org.bd/',
        ),
        _ServiceItem(
          title: 'DAE কৃষি সম্প্রসারণ',
          subtitle: 'Dept. of Agricultural Extension',
          icon: Icons.eco_rounded,
          color: Color(0xFF065F46),
          url: 'https://www.dae.gov.bd/',
        ),
      ],
    ),
    _Service(
      category: 'মৎস্য ও প্রাণিসম্পদ',
      openInWebView: false,
      items: [
        _ServiceItem(
          title: 'DoF মৎস্য অধিদপ্তর',
          subtitle: 'Department of Fisheries',
          icon: Icons.set_meal_rounded,
          color: Color(0xFF0E7490),
          url: 'https://www.fisheries.gov.bd/',
        ),
        _ServiceItem(
          title: 'DLS প্রাণিসম্পদ অধিদপ্তর',
          subtitle: 'Department of Livestock Services',
          icon: Icons.pets_rounded,
          color: Color(0xFF9D174D),
          url: 'https://www.dls.gov.bd/',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + 116 + 12;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      extendBodyBehindAppBar: true,
      appBar: DisasterAppBar(title: 'সরকারি লাইভ সেবা', onMenuTap: onMenuTap),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(16, topPad, 16, 100),
        itemCount: _services.length,
        itemBuilder: (context, i) {
          final section = _services[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      section.category,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(section.items.length, (j) {
                    final item = section.items[j];
                    final isLast = j == section.items.length - 1;
                    return Column(
                      children: [
                        _ServiceTile(
                          item: item,
                          openInWebView: section.openInWebView,
                        ),
                        if (!isLast)
                          Divider(
                            height: 1,
                            indent: 66,
                            endIndent: 16,
                            color: Colors.black.withValues(alpha: 0.07),
                          ),
                      ],
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _ServiceItem item;
  final bool openInWebView;
  const _ServiceTile({required this.item, required this.openInWebView});

  Future<void> _openExternal(BuildContext context) async {
    final uri = Uri.parse(item.url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('লিংক খোলা যায়নি')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (openInWebView) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebViewPage(title: item.title, url: item.url),
              ),
            );
          } else {
            _openExternal(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                    if (!openInWebView)
                      Text(
                        item.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: item.color.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                openInWebView
                    ? Icons.chevron_right_rounded
                    : Icons.open_in_new_rounded,
                color: item.color.withValues(alpha: 0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Service {
  final String category;
  final bool openInWebView;
  final List<_ServiceItem> items;
  const _Service({
    required this.category,
    required this.openInWebView,
    required this.items,
  });
}

class _ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String url;
  const _ServiceItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.url,
  });
}
