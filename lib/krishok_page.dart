import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'providers/weather_provider.dart';
import 'widgets/disaster_app_bar.dart';
import 'widgets/web_view_page.dart';
import 'theme.dart';

class KrishokPage extends StatelessWidget {
  final VoidCallback? onMenuTap;
  const KrishokPage({super.key, this.onMenuTap});

  // Current month → season
  static String _getSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 'বসন্ত/গ্রীষ্ম';
    if (month >= 6 && month <= 9) return 'বর্ষা';
    if (month >= 10 && month <= 11) return 'শরৎ/হেমন্ত';
    return 'শীত';
  }

  static int _getSeasonIndex() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return 0;
    if (month >= 6 && month <= 9) return 1;
    if (month >= 10 && month <= 11) return 2;
    return 3;
  }

  // Season-based crop recommendations
  static const _seasonCrops = [
    // বসন্ত/গ্রীষ্ম
    [
      _CropInfo(
        name: 'পাট',
        icon: '🌿',
        sow: 'মার্চ–এপ্রিল',
        harvest: 'জুলাই–আগস্ট',
        tip: 'পর্যাপ্ত সেচ দিন, আগাছামুক্ত রাখুন।',
        color: Color(0xFF16A34A),
        lightColor: Color(0xFFDCFCE7),
      ),
      _CropInfo(
        name: 'আউশ ধান',
        icon: '🌾',
        sow: 'মার্চ–মে',
        harvest: 'জুলাই–আগস্ট',
        tip: 'উচ্চফলনশীল জাত ব্যবহার করুন।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'মরিচ',
        icon: '🌶️',
        sow: 'ফেব্রুয়ারি–মার্চ',
        harvest: 'মে–জুন',
        tip: 'রোদ বেশি থাকলে সেচ ঘন ঘন দিন।',
        color: Color(0xFFDC2626),
        lightColor: Color(0xFFFEE2E2),
      ),
      _CropInfo(
        name: 'তরমুজ',
        icon: '🍉',
        sow: 'জানুয়ারি–ফেব্রুয়ারি',
        harvest: 'এপ্রিল–মে',
        tip: 'বালু মিশ্রিত মাটিতে ভালো ফলন হয়।',
        color: Color(0xFFDB2777),
        lightColor: Color(0xFFFDF2F8),
      ),
    ],
    // বর্ষা
    [
      _CropInfo(
        name: 'আমন ধান',
        icon: '🌾',
        sow: 'জুন–জুলাই',
        harvest: 'নভেম্বর–ডিসেম্বর',
        tip: 'বন্যাসহিষ্ণু জাত বেছে নিন।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'পাট',
        icon: '🌿',
        sow: 'জুন–জুলাই',
        harvest: 'সেপ্টেম্বর–অক্টোবর',
        tip: 'জলাবদ্ধতা এড়াতে উঁচু জমি বেছে নিন।',
        color: Color(0xFF16A34A),
        lightColor: Color(0xFFDCFCE7),
      ),
      _CropInfo(
        name: 'করলা',
        icon: '🥒',
        sow: 'জুন',
        harvest: 'আগস্ট–সেপ্টেম্বর',
        tip: 'মাচা তৈরি করে চাষ করুন।',
        color: Color(0xFF059669),
        lightColor: Color(0xFFF0FDF4),
      ),
      _CropInfo(
        name: 'ঝিঙ্গা',
        icon: '🫑',
        sow: 'মে–জুন',
        harvest: 'আগস্ট–সেপ্টেম্বর',
        tip: 'নিয়মিত পানি দিন।',
        color: Color(0xFF0891B2),
        lightColor: Color(0xFFECFEFF),
      ),
    ],
    // শরৎ/হেমন্ত
    [
      _CropInfo(
        name: 'আলু',
        icon: '🥔',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'জানুয়ারি–ফেব্রুয়ারি',
        tip: 'ভালো নিষ্কাশন ব্যবস্থা রাখুন।',
        color: Color(0xFFB45309),
        lightColor: Color(0xFFFFFBEB),
      ),
      _CropInfo(
        name: 'সরিষা',
        icon: '🌻',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'জানুয়ারি–ফেব্রুয়ারি',
        tip: 'শুষ্ক আবহাওয়ায় ভালো ফলন হয়।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'মসুর',
        icon: '🫘',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'মার্চ–এপ্রিল',
        tip: 'কম সেচে ভালো ফলন দেয়।',
        color: Color(0xFF0284C7),
        lightColor: Color(0xFFF0F9FF),
      ),
      _CropInfo(
        name: 'ফুলকপি',
        icon: '🥦',
        sow: 'সেপ্টেম্বর–অক্টোবর',
        harvest: 'ডিসেম্বর–জানুয়ারি',
        tip: 'ঠান্ডা আবহাওয়ায় ভালো জন্মে।',
        color: Color(0xFF16A34A),
        lightColor: Color(0xFFDCFCE7),
      ),
    ],
    // শীত
    [
      _CropInfo(
        name: 'বোরো ধান',
        icon: '🌾',
        sow: 'জানুয়ারি–ফেব্রুয়ারি',
        harvest: 'মে–জুন',
        tip: 'পর্যাপ্ত সার ও সেচ দিন।',
        color: Color(0xFFCA8A04),
        lightColor: Color(0xFFFEF9C3),
      ),
      _CropInfo(
        name: 'গম',
        icon: '🌾',
        sow: 'নভেম্বর–ডিসেম্বর',
        harvest: 'মার্চ–এপ্রিল',
        tip: 'কম আর্দ্রতায় চাষ উপযোগী।',
        color: Color(0xFFB45309),
        lightColor: Color(0xFFFFFBEB),
      ),
      _CropInfo(
        name: 'টমেটো',
        icon: '🍅',
        sow: 'অক্টোবর–নভেম্বর',
        harvest: 'জানুয়ারি–ফেব্রুয়ারি',
        tip: 'ঠান্ডা আবহাওয়ায় উৎপাদন বেশি।',
        color: Color(0xFFDC2626),
        lightColor: Color(0xFFFEE2E2),
      ),
      _CropInfo(
        name: 'পেঁয়াজ',
        icon: '🧅',
        sow: 'নভেম্বর',
        harvest: 'মার্চ–এপ্রিল',
        tip: 'শুষ্ক মাটি ও রোদ প্রয়োজন।',
        color: Color(0xFFDB2777),
        lightColor: Color(0xFFFDF2F8),
      ),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final weather = context.watch<WeatherProvider>();
    final seasonIdx = _getSeasonIndex();
    final crops = _seasonCrops[seasonIdx];
    final currentSeason = _getSeason();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      extendBodyBehindAppBar: true,
      appBar: DisasterAppBar(
        title: 'কৃষক সেবা',
        showMenuButton: true,
        onMenuTap: onMenuTap,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          MediaQuery.of(context).padding.top + 116 + 12,
          16,
          120,
        ),
        children: [
          // Page header
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'কৃষক সেবা',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Weather Summary Card ──────────────────────────────────────
          _WeatherSummaryCard(weather: weather),
          const SizedBox(height: 18),

          // ── Crop Alert based on weather ───────────────────────────────
          _CropWeatherAlert(weather: weather),
          const SizedBox(height: 18),

          // ── Pest & Disease Epidemiological Alert ──────────────────────
          Row(
            children: [
              const Icon(
                Icons.biotech_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'রোগ ও পোকামাকড় সতর্কতা (BAMIS)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PestDiseaseWatch(weather: weather),
          const SizedBox(height: 20),

          // ── Cyclone Signal Guidance ───────────────────────────────────
          const _CycloneSignalGuidance(),
          const SizedBox(height: 18),

          // ── FFWC Flood Risk Bulletin ──────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.flood_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'নদী বন্যা পূর্বাভাস (FFWC)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _FloodRiskBulletin(),
          const SizedBox(height: 20),

          // ── Drought Monitor ───────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.crisis_alert_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'খরা পর্যবেক্ষণ (SADMS)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DroughtMonitorPanel(weather: weather),
          const SizedBox(height: 20),

          // ── Seasonal Crop Recommendations ─────────────────────────────
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Text(
                '$currentSeason মৌসুমের ফসল',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: crops.length,
            itemBuilder: (context, i) => _CropCard(info: crops[i]),
          ),
          const SizedBox(height: 20),

          // ── Farming Tips ─────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.tips_and_updates_rounded,
                color: Color(0xFFCA8A04),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'কৃষি পরামর্শ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _FarmingTips(),
          const SizedBox(height: 20),

          // ── Soil & Fertilizer Tips ────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.agriculture_rounded,
                color: Color(0xFFB45309),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'মাটি ও সার ব্যবস্থাপনা',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _SoilFertilizerSection(),
          const SizedBox(height: 20),

          // ── Emergency Contacts for Farmers ───────────────────────────
          Row(
            children: [
              const Icon(
                Icons.phone_in_talk_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'কৃষি হেল্পলাইন',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B2A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AgriHelplines(),
          const SizedBox(height: 20),

          // ── BD Seed Varieties ────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.grass_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'উন্নত জাতের বীজ পরামর্শ',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _BDSeedVarieties(),
          const SizedBox(height: 20),

          // ── Market Price Intelligence ─────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.show_chart_rounded,
                color: Color(0xFF0891B2),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'বাজার মূল্য ও প্রবণতা (DAM)',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MarketPriceDashboard(),
          const SizedBox(height: 20),

          // ── Flood & Drought ──────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.water_rounded,
                color: Color(0xFF0284C7),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'বন্যা ও খরা ব্যবস্থাপনা',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _FloodDroughtAdvisory(),
          const SizedBox(height: 20),

          // ── Govt Support ─────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'সরকারি কৃষি সহায়তা',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _GovtAgriSupport(),
          const SizedBox(height: 20),

          // ── Agri Loan & Insurance ────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.savings_rounded,
                color: Color(0xFF16A34A),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'কৃষি ঋণ ও বীমা',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _AgriLoanInsurance(),
        ],
      ),
    );
  }
}

// ── Weather Summary Card ───────────────────────────────────────────────────────

class _WeatherSummaryCard extends StatelessWidget {
  final WeatherProvider weather;
  const _WeatherSummaryCard({required this.weather});

  @override
  Widget build(BuildContext context) {
    final data = weather.weatherData;
    final temp = data?.currentTemp.toStringAsFixed(0) ?? '--';
    final humidity = data?.currentHumidity.toStringAsFixed(0) ?? '--';
    final wind = data?.currentWindSpeed.toStringAsFixed(0) ?? '--';
    final desc = data?.currentDescription ?? 'তথ্য নেই';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'আজকের আবহাওয়া',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B2A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _WeatherStat(
                icon: Icons.thermostat_rounded,
                label: 'তাপমাত্রা',
                value: '$temp°C',
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 12),
              _WeatherStat(
                icon: Icons.water_drop_rounded,
                label: 'আর্দ্রতা',
                value: '$humidity%',
                color: const Color(0xFF0284C7),
              ),
              const SizedBox(width: 12),
              _WeatherStat(
                icon: Icons.air_rounded,
                label: 'বায়ু',
                value: '$wind km/h',
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '☁ $desc',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _WeatherStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Crop weather alert ─────────────────────────────────────────────────────────

class _CropWeatherAlert extends StatelessWidget {
  final WeatherProvider weather;
  const _CropWeatherAlert({required this.weather});

  @override
  Widget build(BuildContext context) {
    final data = weather.weatherData;
    if (data == null) return const SizedBox.shrink();

    final temp = data.currentTemp;
    final humidity = data.currentHumidity;
    final wind = data.currentWindSpeed;

    String advice;
    Color color;
    Color lightColor;
    IconData icon;

    if (wind > 60) {
      advice =
          'বাতাসের গতি বেশি। ফসল রক্ষায় খুঁটি ও বেড়া দিন। পাকা ফসল দ্রুত কাটুন।';
      color = const Color(0xFFDC2626);
      lightColor = const Color(0xFFFEE2E2);
      icon = Icons.warning_amber_rounded;
    } else if (humidity > 85) {
      advice =
          'আর্দ্রতা বেশি থাকায় ছত্রাকজনিত রোগের ঝুঁকি আছে। ফাঙ্গিসাইড স্প্রে করুন।';
      color = const Color(0xFFCA8A04);
      lightColor = const Color(0xFFFEF9C3);
      icon = Icons.cloud_rounded;
    } else if (temp > 35) {
      advice =
          'তাপমাত্রা বেশি। সকাল বা বিকেলে সেচ দিন। ফসলের গোড়ায় মালচিং করুন।';
      color = const Color(0xFFEA580C);
      lightColor = const Color(0xFFFFEDD5);
      icon = Icons.wb_sunny_rounded;
    } else if (temp < 12) {
      advice =
          'ঠান্ডা আবহাওয়া। চারা গাছ ঢেকে রাখুন। শীতকালীন ফসলের জন্য উপযুক্ত সময়।';
      color = const Color(0xFF0284C7);
      lightColor = const Color(0xFFF0F9FF);
      icon = Icons.ac_unit_rounded;
    } else {
      advice = 'আবহাওয়া ফসল চাষের জন্য অনুকূল। নিয়মিত পরিচর্যা চালিয়ে যান।';
      color = const Color(0xFF16A34A);
      lightColor = const Color(0xFFDCFCE7);
      icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'আবহাওয়াভিত্তিক পরামর্শ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Crop Card ─────────────────────────────────────────────────────────────────

class _CropInfo {
  final String name;
  final String icon;
  final String sow;
  final String harvest;
  final String tip;
  final Color color;
  final Color lightColor;
  const _CropInfo({
    required this.name,
    required this.icon,
    required this.sow,
    required this.harvest,
    required this.tip,
    required this.color,
    required this.lightColor,
  });
}

class _CropCard extends StatelessWidget {
  final _CropInfo info;
  const _CropCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: info.lightColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(info.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  info.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: info.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'বপন', value: info.sow),
          const SizedBox(height: 4),
          _InfoRow(label: 'কাটা', value: info.harvest),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: info.lightColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              info.tip,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Farming Tips ──────────────────────────────────────────────────────────────

class _FarmingTips extends StatelessWidget {
  const _FarmingTips();

  static const _tips = [
    (
      icon: Icons.water_drop_rounded,
      title: 'সঠিক সেচ',
      desc: 'ভোরবেলা বা সন্ধ্যায় সেচ দিন। অতিরিক্ত সেচ শিকড় পচন সৃষ্টি করে।',
      color: Color(0xFF0284C7),
    ),
    (
      icon: Icons.opacity_rounded,
      title: 'পর্যায়ক্রমে শুকানো-ভেজানো (AWD) সেচ',
      desc:
          'ধানখেতে পঁচনালির সাহায্যে মাঠ শুকিয়ে গেলে আবার সেচ দিন। এতে সেচের পানি প্রায় ৩০% কমে ও ইনপুট খরচ কমে। IRAS-প্রসারিত পদ্ধতি।',
      color: Color(0xFF0891B2),
    ),
    (
      icon: Icons.shield_rounded,
      title: 'সমন্বিত বালাই ব্যবস্থাপনা',
      desc:
          'জৈব কীটনাশক, হলুদ আঠালো ফাঁদ ও পরিষ্কার চাষ পদ্ধতিতে ফসল রক্ষা করুন।',
      color: Color(0xFFDC2626),
    ),
    (
      icon: Icons.compost_outlined,
      title: 'জৈব সার',
      desc: 'রাসায়নিকের পাশাপাশি কম্পোস্ট ও ভার্মিকম্পোস্ট ব্যবহার করুন।',
      color: Color(0xFF16A34A),
    ),
    (
      icon: Icons.rotate_right_rounded,
      title: 'ফসল আবর্তন',
      desc:
          'একই জমিতে বারবার একই ফসল না লাগিয়ে পর্যায়ক্রমে ভিন্ন ফসল চাষ করুন।',
      color: Color(0xFFCA8A04),
    ),
    (
      icon: Icons.thermostat_rounded,
      title: 'গ্রোয়িং ডিগ্রি ডে (GDD) ব্যবস্থাপনা',
      desc:
          'ফসলের বাড়ন্তির পর্যায় নির্ণয়ে দৈনিক সর্বোচ্চ ও সর্বনিম্ন তাপমাত্রা যোগ করে ২ দিয়ে ভাগ করুন। GDD সংগ্রহ করলে কাটাইয়ের সঠিক সময় জানতে পারবেন।',
      color: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tips
          .map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tip.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tip.icon, color: tip.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: tip.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip.desc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Soil & Fertilizer Section ─────────────────────────────────────────────────

class _SoilFertilizerSection extends StatelessWidget {
  const _SoilFertilizerSection();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          _SoilRow(
            title: 'মাটি পরীক্ষা (SRDI)',
            desc:
                'প্রতি ৩ বছরে একবার মাটি পরীক্ষা করুন। SRDI উপজেলা নির্দেশিকা অনুযায়ী সার সুপারিশ নিন। হেল্পলাইন: 01777-765310।',
            icon: '🧪',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'ইউরিয়া সার (নাইট্রোজেন)',
            desc:
                'ধানে হেক্টরপ্রতি ১৬০–২৪০ কেজি। বৃষ্টির আগে প্রয়োগ এড়িয়ে চলুন — রানঅফে অপচয় হয়।',
            icon: '⚗️',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'TSP সার (ফসফরাস)',
            desc:
                'শিকড় বৃদ্ধি ও ফুল-ফল ধারণে সহায়তা করে। রোপণের সময় মাটিতে মিশিয়ে দিন।',
            icon: '🌱',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'পটাশ সার (MOP/SOP)',
            desc:
                'ফসলের রোগ প্রতিরোধ ক্ষমতা ও কোষ-প্রাচীর মজবুত করে। ফলের মান ও স্টোরেজ বাড়ায়।',
            icon: '💪',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'উপকূলীয় মাটির লবণ (Salinity)',
            desc:
                'বরিশাল, খুলনা, সাতক্ষীরা অঞ্চলে লোনা মাটিতে লবণসহিষ্ণু জাত (BRRI dhan47, dhan61) ব্যবহার করুন। SRDI হেল্পলাইনে পরামর্শ নিন।',
            icon: '🌊',
          ),
          const Divider(height: 20),
          _SoilRow(
            title: 'কৃষি-পরিবেশ অঞ্চল (AEZ)',
            desc:
                'বাংলাদেশে ৩০টি AEZ রয়েছে। আপনার অঞ্চলের AEZ-ভিত্তিক ফসল-তালিকার জন্য BARC ফসল অঞ্চলায়ন তথ্য সংগ্রহ করুন।',
            icon: '🗺️',
          ),
        ],
      ),
    );
  }
}

class _SoilRow extends StatelessWidget {
  final String title;
  final String desc;
  final String icon;
  const _SoilRow({required this.title, required this.desc, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0D1B2A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Agri Helplines ────────────────────────────────────────────────────────────

class _AgriHelplines extends StatelessWidget {
  const _AgriHelplines();

  @override
  Widget build(BuildContext context) {
    final lines = [
      (
        number: '16123',
        label: 'কৃষি তথ্য সার্ভিস (AIS)',
        icon: Icons.agriculture_rounded,
      ),
      (
        number: '333',
        label: 'জাতীয় কৃষি হেল্পলাইন',
        icon: Icons.phone_rounded,
      ),
      (
        number: '16321',
        label: 'বাংলাদেশ কৃষি ব্যাংক (BKB)',
        icon: Icons.account_balance_rounded,
      ),
      (
        number: '16180',
        label: 'কৃষি সম্প্রসারণ অধিদপ্তর (DAE)',
        icon: Icons.support_agent_rounded,
      ),
      (number: '16135', label: 'BADC বীজ ও সার', icon: Icons.grass_rounded),
      (
        number: '02-9559900',
        label: 'FFWC বন্যা পূর্বাভাস কেন্দ্র',
        icon: Icons.flood_rounded,
      ),
      (
        number: '1090',
        label: 'আবহাওয়া অধিদপ্তর (BMD)',
        icon: Icons.cloud_rounded,
      ),
      (
        number: '16108',
        label: 'কৃষি বিপণন অধিদপ্তর (DAM)',
        icon: Icons.store_rounded,
      ),
    ];
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(lines.length, (i) {
          final line = lines[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    line.icon,
                    color: const Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
                title: Text(
                  line.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                trailing: Text(
                  line.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              if (i < lines.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

// ── Cyclone Signal-Based Farmer Guidance ────────────────────────────────────

class _CycloneSignalGuidance extends StatelessWidget {
  const _CycloneSignalGuidance();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ঝড় সংকেত ও করণীয়',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    Text(
                      'প্রতিটি সংকেতে কৃষকের জন্য নির্দেশনা',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._signalGuidelines.map((guide) => _SignalGuideCard(guide: guide)),
        ],
      ),
    );
  }
}

class _SignalGuideCard extends StatefulWidget {
  final _SignalGuide guide;
  const _SignalGuideCard({required this.guide});

  @override
  State<_SignalGuideCard> createState() => _SignalGuideCardState();
}

class _SignalGuideCardState extends State<_SignalGuideCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.guide.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.guide.color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.guide.color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: widget.guide.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.guide.signal,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.guide.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: widget.guide.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.guide.windSpeed,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: widget.guide.color,
                      size: 24,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.agriculture_rounded,
                              size: 16,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'কৃষকের করণীয়:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...widget.guide.actions.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    action,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignalGuide {
  final String signal;
  final String name;
  final String windSpeed;
  final Color color;
  final List<String> actions;
  const _SignalGuide({
    required this.signal,
    required this.name,
    required this.windSpeed,
    required this.color,
    required this.actions,
  });
}

final List<_SignalGuide> _signalGuidelines = [
  _SignalGuide(
    signal: '১',
    name: 'দূরবর্তী সতর্কতা-১',
    windSpeed: 'বাতাস: ৪০-৫০ কিমি/ঘণ্টা',
    color: const Color(0xFF059669),
    actions: [
      'আবহাওয়া পূর্বাভাস নিয়মিত শুনুন',
      'জরুরি সরঞ্জাম প্রস্তুত রাখুন',
      'ফসলের অবস্থা পরীক্ষা করুন',
    ],
  ),
  _SignalGuide(
    signal: '২',
    name: 'দূরবর্তী সতর্কতা-২',
    windSpeed: 'বাতাস: ৫০-৬০ কিমি/ঘণ্টা',
    color: const Color(0xFF0284C7),
    actions: [
      'দুর্বল গাছের ডালপালা কেটে ফেলুন',
      'সেচ বন্ধ রাখুন',
      'পশুখাদ্য সংরক্ষণ করুন',
    ],
  ),
  _SignalGuide(
    signal: '৩',
    name: 'দূরবর্তী হুঁশিয়ারি-৩',
    windSpeed: 'বাতাস: ৬০-৮০ কিমি/ঘণ্টা',
    color: const Color(0xFFEAB308),
    actions: [
      'পাকা ফসল দ্রুত সংগ্রহ করুন',
      'জলাবদ্ধতা নিষ্কাশনের ব্যবস্থা করুন',
      'মাছ চাষের জাল পরীক্ষা করুন',
      'গবাদি পশু নিরাপদ স্থানে সরান',
    ],
  ),
  _SignalGuide(
    signal: '৪',
    name: 'স্থানীয় সতর্কতা-৪',
    windSpeed: 'বাতাস: ৮০-৮৯ কিমি/ঘণ্টা',
    color: const Color(0xFFF59E0B),
    actions: [
      'ফসলের মাঠে কাজ বন্ধ রাখুন',
      'সার ও কীটনাশক সুরক্ষিত রাখুন',
      'কৃষি যন্ত্রপাতি ঘরে তুলুন',
      'পুকুরে বাঁধ মজবুত করুন',
    ],
  ),
  _SignalGuide(
    signal: '৫',
    name: 'নদীবন্দর সতর্কতা',
    windSpeed: 'বাতাস: ৪০-৬১ কিমি/ঘণ্টা (নদী)',
    color: const Color(0xFF7C3AED),
    actions: [
      'নদীতীরে চাষাবাদ স্থগিত রাখুন',
      'বন্যার পূর্বাভাসে সতর্ক থাকুন',
      'নিচু জমির ফসল সরিয়ে নিন',
    ],
  ),
  _SignalGuide(
    signal: '৬',
    name: 'সমুদ্রবন্দর সতর্কতা',
    windSpeed: 'বাতাস: ৬১-৮৮ কিমি/ঘণ্টা (সমুদ্র)',
    color: const Color(0xFF2563EB),
    actions: [
      'উপকূলীয় এলাকায় চাষ বন্ধ রাখুন',
      'লবণ পানির প্রভাব থেকে জমি রক্ষা করুন',
      'ধান ক্ষেতে বাঁধ দিন',
    ],
  ),
  _SignalGuide(
    signal: '৭',
    name: 'বিপদ সংকেত-৭',
    windSpeed: 'বাতাস: ৮৯-১১৭ কিমি/ঘণ্টা',
    color: const Color(0xFFDC2626),
    actions: [
      'সব ধরনের কৃষিকাজ বন্ধ রাখুন',
      'জমিতে না যাবেন',
      'নিরাপদ আশ্রয়ে যান',
    ],
  ),
  _SignalGuide(
    signal: '৮',
    name: 'মহাবিপদ সংকেত-৮',
    windSpeed: 'বাতাস: ১১৮-১৩৩ কিমি/ঘণ্টা',
    color: const Color(0xFF991B1B),
    actions: ['শক্ত আশ্রয়ে অবস্থান করুন', 'সব কৃষি কার্যক্রম পরিত্যাগ করুন'],
  ),
  _SignalGuide(
    signal: '৯',
    name: 'মহাবিপদ সংকেত-৯',
    windSpeed: 'বাতাস: ১৩৪-১৬৬ কিমি/ঘণ্টা',
    color: const Color(0xFF7F1D1D),
    actions: ['আশ্রয়কেন্দ্রে অবস্থান করুন', 'জরুরি খাবার ও পানি সাথে রাখুন'],
  ),
  _SignalGuide(
    signal: '১০',
    name: 'মহাবিপদ সংকেত-১০',
    windSpeed: 'বাতাস: >১৬৬ কিমি/ঘণ্টা',
    color: const Color(0xFF450A0A),
    actions: ['পাকা আশ্রয়কেন্দ্রেই থাকুন', 'বাহিরে একদম যাবেন না'],
  ),
];

// ── BD Seed Varieties ─────────────────────────────────────────────────────────

class _BDSeedVarieties extends StatelessWidget {
  const _BDSeedVarieties();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _VarietyTile(
            icon: '🌾',
            crop: 'বোরো ধান',
            varieties: 'BRRI dhan28, dhan29, dhan88',
            note: 'জানু–ফেব্রু বপন | হেক্টরপ্রতি ৬-৮ টন',
            color: Color(0xFFCA8A04),
            isLast: false,
          ),
          _VarietyTile(
            icon: '🌾',
            crop: 'আমন ধান',
            varieties: 'BRRI dhan49, dhan52, dhan54',
            note: 'dhan52 বন্যাসহিষ্ণু — হাওর এলাকার জন্য উত্তম',
            color: Color(0xFF16A34A),
            isLast: false,
          ),
          _VarietyTile(
            icon: '🌾',
            crop: 'আউশ ধান',
            varieties: 'BRRI dhan48, Binadhan-19',
            note: 'খরাসহিষ্ণু — কম সেচে ভালো ফলন',
            color: Color(0xFF059669),
            isLast: false,
          ),
          _VarietyTile(
            icon: '🌻',
            crop: 'সরিষা',
            varieties: 'BARI সরিষা-14, BARI সরিষা-17',
            note: 'অক্টো–নভে বপন | ৮৫-৯০ দিনে কাটাই',
            color: Color(0xFFB45309),
            isLast: false,
          ),
          _VarietyTile(
            icon: '🥔',
            crop: 'আলু',
            varieties: 'BARI আলু-25, BARI আলু-72',
            note: 'অক্টো–নভে লাগান | হেক্টরপ্রতি ২৫-৩০ টন',
            color: Color(0xFF92400E),
            isLast: false,
          ),
          _VarietyTile(
            icon: '🌽',
            crop: 'ভুট্টা',
            varieties: 'BARI হাইব্রিড ভুট্টা-9',
            note: 'হেক্টরপ্রতি ১০-১২ টন সম্ভব',
            color: Color(0xFFEA580C),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _VarietyTile extends StatelessWidget {
  final String icon;
  final String crop;
  final String varieties;
  final String note;
  final Color color;
  final bool isLast;
  const _VarietyTile({
    required this.icon,
    required this.crop,
    required this.varieties,
    required this.note,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      varieties,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ── Flood & Drought Advisory ──────────────────────────────────────────────────

const _floodTips = [
  'বন্যাসহিষ্ণু জাত (BRRI dhan52, dhan54) চাষ করুন',
  'বন্যার আগেই পাকা ও আধাপাকা ফসল দ্রুত কেটে নিন',
  'পানি নেমে যাওয়ার পর সাথে সাথে পটাশ সার ব্যবহার করুন',
  'জলাবদ্ধতা দূর করতে সরু নালা কেটে পানি সরিয়ে দিন',
  'বন্যার পরে পচা নাড়া মাটিতে মিশিয়ে জমি উর্বর করুন',
  'নতুন রোপণের জন্য বীজতলা আগে থেকেই তৈরি রাখুন',
];

const _droughtTips = [
  'খরাসহিষ্ণু জাত (BRRI dhan48, Binadhan-19) বেছে নিন',
  'সকালে বা বিকেলে সেচ দিন — দুপুরে দিলে পানির অপচয় বেশি',
  'মাল্চিং (খড় বিছানো) করে মাটির রস ধরে রাখুন',
  'ডিপ টিউবওয়েল ও শ্যালো টিউবওয়েলে সেচ পরিকল্পনা করুন',
  'বরেন্দ্র অঞ্চলে BMDA হেল্পলাইন: 0721-774547',
  'বৃষ্টির পানি সংরক্ষণে ছোট পুকুর বা ডোবা ব্যবহার করুন',
];

class _FloodDroughtAdvisory extends StatelessWidget {
  const _FloodDroughtAdvisory();

  Widget _bullet(String text, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: dotColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_rounded,
                      color: Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'বন্যার সময় করণীয়',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        Text(
                          'হাওর ও নিচু এলাকার কৃষকদের জন্য',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._floodTips.map((t) => _bullet(t, const Color(0xFF0284C7))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Color(0xFFEA580C),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'খরার সময় করণীয়',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        Text(
                          'উত্তরবঙ্গ ও বরেন্দ্র অঞ্চলের কৃষকদের জন্য',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._droughtTips.map((t) => _bullet(t, const Color(0xFFEA580C))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Govt Agri Support ─────────────────────────────────────────────────────────

class _GovtAgriSupport extends StatelessWidget {
  const _GovtAgriSupport();

  @override
  Widget build(BuildContext context) {
    const schemes = [
      _SchemeInfo(
        icon: '🌱',
        title: 'কৃষি প্রণোদনা ও পুনর্বাসন',
        desc:
            'প্রাকৃতিক দুর্যোগে ক্ষতিগ্রস্ত কৃষকদের জন্য বিনামূল্যে বীজ ও সার। স্থানীয় উপজেলা কৃষি অফিসে যোগাযোগ করুন।',
        color: Color(0xFF16A34A),
      ),
      _SchemeInfo(
        icon: '💳',
        title: 'কৃষক কার্ড ও ভর্তুকি',
        desc:
            'কৃষক কার্ডের মাধ্যমে ভর্তুকি মূল্যে সার পাওয়া যায়। ইউনিয়ন পরিষদ বা উপজেলা DAE অফিস থেকে কার্ড তৈরি করুন।',
        color: Color(0xFF0284C7),
      ),
      _SchemeInfo(
        icon: '🏭',
        title: 'BADC বীজ ও সার',
        desc:
            'বাংলাদেশ কৃষি উন্নয়ন করপোরেশন থেকে উচ্চফলনশীল বীজ ও সার সংগ্রহ করুন। হেল্পলাইন: 16135।',
        color: Color(0xFFCA8A04),
      ),
      _SchemeInfo(
        icon: '🚜',
        title: 'কৃষি যন্ত্রপাতি ভর্তুকি',
        desc:
            'সরকার থেকে ৫০-৭০% ভর্তুকিতে ধান কাটার মেশিন ও পাওয়ার টিলার পাওয়া যায়। উপজেলা কৃষি অফিসে আবেদন করুন।',
        color: Color(0xFF7C3AED),
      ),
      _SchemeInfo(
        icon: '📋',
        title: 'ডিজিটাল কৃষি সেবা (AIS)',
        desc:
            'কৃষি তথ্য সার্ভিস থেকে আধুনিক চাষ পদ্ধতির তথ্য পান। ফোন: 16123। SMS: 1616 তে KRISHI লিখে পাঠান।',
        color: Color(0xFF059669),
      ),
      _SchemeInfo(
        icon: '🏦',
        title: '১০ টাকায় কৃষক অ্যাকাউন্ট',
        desc:
            'বাংলাদেশ কৃষি ব্যাংক বা সোনালী ব্যাংকে ১০ টাকায় হিসাব খুলুন এবং সরকারি ভর্তুকি সরাসরি পান।',
        color: Color(0xFF0891B2),
      ),
    ];
    return Column(
      children: schemes
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: s.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.desc,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SchemeInfo {
  final String icon;
  final String title;
  final String desc;
  final Color color;
  const _SchemeInfo({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

// ── Agri Loan & Insurance ─────────────────────────────────────────────────────

class _AgriLoanInsurance extends StatelessWidget {
  const _AgriLoanInsurance();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: const [
          _LoanTile(
            icon: Icons.account_balance_rounded,
            title: 'বাংলাদেশ কৃষি ব্যাংক (BKB)',
            desc: '৪% সুদে শস্য ঋণ। ফসল, মৎস্য ও পশুপালন ঋণ পাওয়া যায়।',
            contact: '16321',
            color: Color(0xFF16A34A),
            isLast: false,
          ),
          _LoanTile(
            icon: Icons.account_balance_rounded,
            title: 'রাজশাহী কৃষি উন্নয়ন ব্যাংক (RAKUB)',
            desc: 'উত্তরবঙ্গের কৃষকদের জন্য বিশেষ ঋণ ও অনুদান সুবিধা।',
            contact: '0721-774000',
            color: Color(0xFF0284C7),
            isLast: false,
          ),
          _LoanTile(
            icon: Icons.health_and_safety_rounded,
            title: 'সাধারণ বীমা কর্পোরেশন',
            desc:
                'ফসল বিমা: ঘূর্ণিঝড়, বন্যা ও খরায় ক্ষতিপূরণ পান। স্থানীয় শাখায় আবেদন করুন।',
            contact: '16130',
            color: Color(0xFF7C3AED),
            isLast: false,
          ),
          _LoanTile(
            icon: Icons.volunteer_activism_rounded,
            title: 'কৃষি উপকরণ সহায়তা (DAE)',
            desc:
                'দুর্যোগ পরবর্তী বিনামূল্যে বীজ, সার ও কীটনাশক পেতে উপজেলা কৃষি অফিসে যোগাযোগ করুন।',
            contact: '16123',
            color: Color(0xFFCA8A04),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final String contact;
  final Color color;
  final bool isLast;
  const _LoanTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.contact,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_rounded,
                          size: 12,
                          color: Colors.black45,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contact,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}

// ── Pest & Disease Epidemiological Alert ──────────────────────────────────────

enum _Risk { low, medium, high }

class _DiseaseRisk {
  final String name;
  final String pathogen;
  final _Risk risk;
  final String crops;
  final String remedy;
  final String prevention;
  const _DiseaseRisk({
    required this.name,
    required this.pathogen,
    required this.risk,
    required this.crops,
    required this.remedy,
    required this.prevention,
  });
}

class _PestDiseaseWatch extends StatelessWidget {
  final WeatherProvider weather;
  const _PestDiseaseWatch({required this.weather});

  static List<_DiseaseRisk> _calcRisks(
    double temp,
    double humidity,
    int seasonIdx,
  ) {
    final risks = <_DiseaseRisk>[];

    if (humidity > 78 && temp >= 18 && temp <= 30) {
      risks.add(
        const _DiseaseRisk(
          name: 'ধানের ব্লাস্ট রোগ',
          pathogen: 'Pyricularia oryzae',
          risk: _Risk.medium,
          crops: 'ধান (বোরো / আমন)',
          remedy:
              'ট্রাইসাইক্লাজল ৭৫% WP ০.৫ গ্রাম/লি পানিতে মিশিয়ে স্প্রে করুন।',
          prevention:
              'আক্রান্ত গোছা উপড়ে ফেলুন, ইউরিয়া সার সাময়িক বন্ধ রাখুন।',
        ),
      );
    }

    if (humidity > 85 && temp >= 25 && temp <= 35) {
      risks.add(
        const _DiseaseRisk(
          name: 'শিথ ব্লাইট (খোল পচা)',
          pathogen: 'Rhizoctonia solani',
          risk: _Risk.medium,
          crops: 'ধান, ভুট্টা',
          remedy: 'হেক্সাকোনাজল ২% WP জমিতে প্রয়োগ করুন।',
          prevention: 'ঘন রোপণ এড়িয়ে চলুন, নাইট্রোজেন সার পরিমিতভাবে দিন।',
        ),
      );
    }

    if (temp > 32 && humidity < 60) {
      risks.add(
        const _DiseaseRisk(
          name: 'জাবপোকা ও সাদামাছি',
          pathogen: 'Aphididae / Bemisia tabaci',
          risk: _Risk.medium,
          crops: 'সবজি, পাট, সরিষা',
          remedy:
              'ইমিডাক্লোপ্রিড ৫% EC স্প্রে করুন অথবা পীতবর্ণ আঠালো ফাঁদ ব্যবহার করুন।',
          prevention: 'পরিষ্কার চাষ, সন্ধ্যায় হালকা সেচ দিন।',
        ),
      );
    }

    if (seasonIdx == 1 && temp >= 25 && humidity > 70) {
      risks.add(
        const _DiseaseRisk(
          name: 'ধানের কাণ্ড পচা পোকা',
          pathogen: 'Scirpophaga incertulas',
          risk: _Risk.medium,
          crops: 'আমন ও বোরো ধান',
          remedy:
              'কারটাপ হাইড্রোক্লোরাইড ৫০% SP ১.৫ গ্রাম/লি পানিতে স্প্রে করুন।',
          prevention: 'আলোক ফাঁদ (Light Trap) ব্যবহার করুন, ডিম ধ্বংস করুন।',
        ),
      );
    }

    if (temp >= 12 && temp <= 22 && humidity > 85) {
      risks.add(
        const _DiseaseRisk(
          name: 'আলুর মড়ক রোগ (Late Blight)',
          pathogen: 'Phytophthora infestans',
          risk: _Risk.medium,
          crops: 'আলু, টমেটো, বেগুন',
          remedy:
              'ম্যানকোজেব ৮০% WP ২ গ্রাম/লি পানিতে প্রতি ৭ দিনে স্প্রে করুন।',
          prevention: 'রোগমুক্ত বীজ ব্যবহার করুন, খেতে পানি না জমতে দিন।',
        ),
      );
    }

    if (risks.isEmpty) {
      risks.add(
        const _DiseaseRisk(
          name: 'রোগ ও পোকার ঝুঁকি কম',
          pathogen: '',
          risk: _Risk.low,
          crops: 'সকল ফসল',
          remedy: 'নিয়মিত মাঠ পরিদর্শন চালিয়ে যান।',
          prevention: 'BAMIS সুপারিশ অনুসরণ করুন।',
        ),
      );
    }
    return risks;
  }

  @override
  Widget build(BuildContext context) {
    final data = weather.weatherData;
    final temp = data?.currentTemp ?? 28.0;
    final humidity = data?.currentHumidity ?? 75.0;
    final si = KrishokPage._getSeasonIndex();
    final risks = _calcRisks(temp, humidity, si);
    return Column(
      children: risks
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DiseaseRiskCard(risk: r),
            ),
          )
          .toList(),
    );
  }
}

class _DiseaseRiskCard extends StatefulWidget {
  final _DiseaseRisk risk;
  const _DiseaseRiskCard({required this.risk});
  @override
  State<_DiseaseRiskCard> createState() => _DiseaseRiskCardState();
}

class _DiseaseRiskCardState extends State<_DiseaseRiskCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final r = widget.risk;
    final Color mainColor;
    final Color bgColor;
    final String riskLabel;
    switch (r.risk) {
      case _Risk.high:
        mainColor = const Color(0xFFDC2626);
        bgColor = const Color(0xFFFEE2E2);
        riskLabel = 'উচ্চ ঝুঁকি';
      case _Risk.medium:
        mainColor = const Color(0xFFCA8A04);
        bgColor = const Color(0xFFFEF9C3);
        riskLabel = 'মাঝারি ঝুঁকি';
      case _Risk.low:
        mainColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFDCFCE7);
        riskLabel = 'ঝুঁকি কম';
    }
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: mainColor.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: r.pathogen.isNotEmpty
              ? () => setState(() => _expanded = !_expanded)
              : null,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        riskLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        r.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: mainColor,
                        ),
                      ),
                    ),
                    if (r.pathogen.isNotEmpty)
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: mainColor,
                        size: 20,
                      ),
                  ],
                ),
                if (r.pathogen.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ফসল: ${r.crops}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.medication_rounded,
                    label: 'প্রতিকার',
                    text: r.remedy,
                    color: mainColor,
                  ),
                  const SizedBox(height: 6),
                  _DetailRow(
                    icon: Icons.security_rounded,
                    label: 'প্রতিরোধ',
                    text: r.prevention,
                    color: mainColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  final Color color;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── FFWC Flood Risk Bulletin ──────────────────────────────────────────────────

enum _FloodStatus { normal, warning, flood, severeFlood }

class _FloodRiskBulletin extends StatelessWidget {
  const _FloodRiskBulletin();

  static _FloodStatus _stationStatus(int idx) {
    final m = DateTime.now().month;
    if (m >= 7 && m <= 9) {
      if (idx == 1) return _FloodStatus.flood;
      if (idx == 0) return _FloodStatus.warning;
    }
    if (m >= 5 && m <= 6) {
      if (idx == 1) return _FloodStatus.warning;
    }
    return _FloodStatus.normal;
  }

  static const _stations = [
    (
      name: 'বাহাদুরাবাদ',
      river: 'যমুনা',
      district: 'জামালপুর',
      danger: '19.50 mMSL',
    ),
    (
      name: 'হার্ডিঞ্জ ব্রিজ',
      river: 'পদ্মা',
      district: 'কুষ্টিয়া',
      danger: '14.25 mMSL',
    ),
    (name: 'চাঁদপুর', river: 'মেঘনা', district: 'চাঁদপুর', danger: '5.00 mMSL'),
    (name: 'সুরমা ঘাট', river: 'সুরমা', district: 'সিলেট', danger: '9.30 mMSL'),
  ];

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusDot(color: const Color(0xFF16A34A), label: 'স্বাভাবিক'),
              const SizedBox(width: 14),
              _StatusDot(color: const Color(0xFFCA8A04), label: 'সতর্কতা'),
              const SizedBox(width: 14),
              _StatusDot(color: const Color(0xFFDC2626), label: 'বন্যা'),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...List.generate(_stations.length, (i) {
            final s = _stations[i];
            final status = _stationStatus(i);
            final Color c;
            final String lbl;
            switch (status) {
              case _FloodStatus.normal:
                c = const Color(0xFF16A34A);
                lbl = 'স্বাভাবিক';
              case _FloodStatus.warning:
                c = const Color(0xFFCA8A04);
                lbl = 'সতর্কতা';
              case _FloodStatus.flood:
                c = const Color(0xFFDC2626);
                lbl = 'বন্যা';
              case _FloodStatus.severeFlood:
                c = const Color(0xFF991B1B);
                lbl = 'মারাত্মক';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${s.name} — ${s.river}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B2A),
                          ),
                        ),
                        Text(
                          '${s.district} | বিপদসীমা: ${s.danger}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      lbl,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: c,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Builder(
            builder: (ctx) => Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Colors.black38,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'FFWC: 02-9559900 | ffwc.bwdb.gov.bd',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => const WebViewPage(
                        title: 'FFWC বন্যা মানচিত্র',
                        url: 'https://www.ffwc.gov.bd/app/flood-magnitude',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text(
                    'লাইভ দেখুন',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

// ── Drought Monitor Panel (SADMS-inspired) ────────────────────────────────────

enum _DroughtSeverity { normal, mild, moderate, severe, extreme }

class _DroughtMonitorPanel extends StatelessWidget {
  final WeatherProvider weather;
  const _DroughtMonitorPanel({required this.weather});

  _DroughtSeverity _severity(double temp, double humidity) {
    final proxy = humidity - (temp - 25) * 1.5;
    if (proxy > 70) return _DroughtSeverity.normal;
    if (proxy > 55) return _DroughtSeverity.mild;
    if (proxy > 40) return _DroughtSeverity.moderate;
    if (proxy > 25) return _DroughtSeverity.severe;
    return _DroughtSeverity.extreme;
  }

  @override
  Widget build(BuildContext context) {
    final data = weather.weatherData;
    final temp = data?.currentTemp ?? 28.0;
    final humidity = data?.currentHumidity ?? 75.0;
    final month = DateTime.now().month;

    final spiVal = (month >= 11 || month <= 3) ? -0.8 : 0.6;
    final vci = humidity > 80 ? 72 : (humidity > 60 ? 55 : 36);
    final smi = humidity > 85 ? 68 : (humidity > 65 ? 48 : 26);
    final sev = _severity(temp, humidity);

    final Color mainColor;
    final String sevBn;
    switch (sev) {
      case _DroughtSeverity.normal:
        mainColor = const Color(0xFF16A34A);
        sevBn = 'স্বাভাবিক';
      case _DroughtSeverity.mild:
        mainColor = const Color(0xFF65A30D);
        sevBn = 'হালকা খরা';
      case _DroughtSeverity.moderate:
        mainColor = const Color(0xFFCA8A04);
        sevBn = 'মাঝারি খরা';
      case _DroughtSeverity.severe:
        mainColor = const Color(0xFFEA580C);
        sevBn = 'তীব্র খরা';
      case _DroughtSeverity.extreme:
        mainColor = const Color(0xFFDC2626);
        sevBn = 'চরম খরা';
    }

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'সমন্বিত খরা সূচক (IDSI)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'তাপমাত্রা: ${temp.toStringAsFixed(0)}°C  |  আর্দ্রতা: ${humidity.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  sevBn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _IndexBar(
            label: 'SPI (বর্ষণ সূচক)',
            value: ((spiVal + 2) / 4).clamp(0.0, 1.0),
            valueText: spiVal.toStringAsFixed(1),
            color: spiVal >= 0
                ? const Color(0xFF0284C7)
                : const Color(0xFFEA580C),
          ),
          const SizedBox(height: 8),
          _IndexBar(
            label: 'VCI (উদ্ভিদ অবস্থা সূচক)',
            value: vci / 100,
            valueText: '$vci%',
            color: vci > 60
                ? const Color(0xFF16A34A)
                : vci > 40
                ? const Color(0xFFCA8A04)
                : const Color(0xFFDC2626),
          ),
          const SizedBox(height: 8),
          _IndexBar(
            label: 'SMI (মাটির আর্দ্রতা সূচক)',
            value: smi / 100,
            valueText: '$smi%',
            color: smi > 60
                ? const Color(0xFF0284C7)
                : smi > 40
                ? const Color(0xFFCA8A04)
                : const Color(0xFFDC2626),
          ),
          if (sev != _DroughtSeverity.normal) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_rounded, size: 16, color: mainColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sev == _DroughtSeverity.mild
                          ? 'হালকা আর্দ্রতার ঘাটতি। পরবর্তী সেচের সময়সূচি এগিয়ে আনুন।'
                          : sev == _DroughtSeverity.moderate
                          ? 'মাটিতে পানির ঘাটতি বাড়ছে। AWD পদ্ধতিতে সেচ দিন ও মালচিং করুন।'
                          : 'মারাত্মক খরার আশঙ্কা! খরাসহিষ্ণু জাত রোপণ করুন। BMDA: 0721-774547।',
                      style: TextStyle(
                        fontSize: 12,
                        color: mainColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'তথ্যসূত্র: SADMS / IWMI / NASA POWER (আনুমানিক মান)',
            style: TextStyle(fontSize: 10, color: Colors.black38),
          ),
        ],
      ),
    );
  }
}

class _IndexBar extends StatelessWidget {
  final String label;
  final double value;
  final String valueText;
  final Color color;
  const _IndexBar({
    required this.label,
    required this.value,
    required this.valueText,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ── Market Price Dashboard (DAM WebView) ─────────────────────────────────────

// Whether in-app WebView is supported on the current platform
bool get _canUseWebView => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class _MarketPriceDashboard extends StatefulWidget {
  const _MarketPriceDashboard();

  @override
  State<_MarketPriceDashboard> createState() => _MarketPriceDashboardState();
}

class _MarketPriceDashboardState extends State<_MarketPriceDashboard> {
  static const _damUrl = 'https://market.dam.gov.bd/';
  static const _webHeight = 480.0;

  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!_canUseWebView) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 12; Pixel 6) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (_) => setState(() {
            _loading = false;
            _hasError = true;
          }),
        ),
      )
      ..loadRequest(Uri.parse(_damUrl));
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── header row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'দৈনিক বাজারদর (DAM লাইভ)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B2A),
                    ),
                  ),
                ),
                if (_canUseWebView && !_hasError)
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: Color(0xFF16A34A),
                    ),
                    tooltip: 'রিফ্রেশ',
                    onPressed: () => _controller.reload(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WebViewPage(
                        title: 'DAM দৈনিক বাজার মূল্য',
                        url: _damUrl,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 13),
                  label: const Text(
                    'পূর্ণ পর্দায়',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── embedded view ─────────────────────────────────────────────
          if (_canUseWebView)
            SizedBox(
              height: _webHeight,
              child: _hasError
                  ? _WebErrorView(
                      onRetry: () {
                        setState(() {
                          _hasError = false;
                          _loading = true;
                        });
                        _controller.reload();
                      },
                    )
                  : Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_loading)
                          const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF16A34A),
                            ),
                          ),
                      ],
                    ),
            )
          else
            _DamLauncherTile(url: _damUrl),

          const Divider(height: 1),

          // ── bottom buttons ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                _LiveButton(
                  label: 'FFWC বন্যা',
                  url: 'https://www.ffwc.gov.bd/app/flood-magnitude',
                  pageTitle: 'FFWC বন্যা মানচিত্র',
                ),
                const SizedBox(width: 10),
                _LiveButton(
                  label: 'Google বন্যা',
                  url:
                      'https://sites.research.google/floods/l/23.957665118872956/91.42051660416591/6.789099225431683',
                  pageTitle: 'Google Flood Map — বাংলাদেশ',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Small inline error state for the embedded WebView
class _WebErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _WebErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36, color: Colors.black26),
          const SizedBox(height: 12),
          const Text(
            'পৃষ্ঠা লোড হয়নি',
            style: TextStyle(fontSize: 13, color: Colors.black45),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('আবার চেষ্টা করুন'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF16A34A),
              side: const BorderSide(color: Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }
}

// Shown on Web/Windows instead of WebView
class _DamLauncherTile extends StatelessWidget {
  final String url;
  const _DamLauncherTile({required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_rounded,
              size: 22,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'কৃষি বিপণন অধিদপ্তর',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                Text(
                  'লাইভ দৈনিক বাজারদর দেখতে ব্রাউজার খুলুন',
                  style: TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              Icons.open_in_browser_rounded,
              color: Color(0xFF16A34A),
            ),
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          ),
        ],
      ),
    );
  }
}

// Reusable live-site launcher button
class _LiveButton extends StatelessWidget {
  final String label;
  final String url;
  final String pageTitle;
  const _LiveButton({
    required this.label,
    required this.url,
    required this.pageTitle,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WebViewPage(title: pageTitle, url: url),
          ),
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 13),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1B5E20),
          side: const BorderSide(color: Color(0xFF1B5E20), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
