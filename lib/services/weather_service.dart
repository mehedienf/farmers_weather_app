// Service that fetches weather data from the Open-Meteo API.
//
// Open-Meteo is a free weather API with no API key required and no rate limits.
// Perfect for farmers' weather apps.
//
// Flow per fetch:
//   1. Single API call with lat/lon → current + 7-day forecast
//   2. Parse temperature, wind, humidity, precipitation, weather codes
//
// Falls back to realistic demo data on any request failure.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _base = 'https://api.open-meteo.com/v1';

  /// Fetches weather for the given [lat]/[lon].
  /// Makes a single API call (no API key needed).
  /// Falls back to demo data on any failure.
  Future<WeatherData> fetchWeather(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        '$_base/forecast?'
        'latitude=$lat&longitude=$lon&'
        'current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&'
        'daily=weather_code,temperature_2m_max,temperature_2m_min,'
        'precipitation_sum,wind_speed_10m_max,relative_humidity_2m_mean&'
        'timezone=Asia/Dhaka',
      );

      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return _parse(json);
      } else {
        return _demoWeatherData();
      }
    } catch (e) {
      return _demoWeatherData();
    }
  }

  /// Parses Open-Meteo response into [WeatherData].
  static WeatherData _parse(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;

    // ── Current conditions ────────────────────────────────────────────────
    final currentTemp = (current['temperature_2m'] as num).toDouble();
    final currentHumidity = (current['relative_humidity_2m'] as num).toDouble();
    final currentWindSpeed = (current['wind_speed_10m'] as num).toDouble();
    final currentWeatherCode = current['weather_code'] as int;
    final currentIconCode = _wmoCodeToIcon(currentWeatherCode, true);
    final currentDescription = _wmoCodeToDescription(currentWeatherCode);

    // ── Daily forecast ────────────────────────────────────────────────────
    final dates = (daily['time'] as List).cast<String>();
    final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final weatherCodes = (daily['weather_code'] as List).cast<int>();
    final precipitation = (daily['precipitation_sum'] as List).cast<num>();
    final windSpeeds = (daily['wind_speed_10m_max'] as List).cast<num>();
    final humidities = (daily['relative_humidity_2m_mean'] as List).cast<num>();

    final dailyForecasts = <DayForecast>[];
    for (var i = 0; i < dates.length; i++) {
      final date = DateTime.parse(dates[i]);
      dailyForecasts.add(
        DayForecast(
          date: date,
          tempMin: minTemps[i].toDouble(),
          tempMax: maxTemps[i].toDouble(),
          humidity: humidities[i].toDouble(),
          windSpeed: windSpeeds[i].toDouble(),
          description: _wmoCodeToDescription(weatherCodes[i]),
          iconCode: _wmoCodeToIcon(weatherCodes[i], false),
          precipitation: precipitation[i].toDouble(),
        ),
      );
    }

    return WeatherData(
      currentTemp: currentTemp,
      currentWindSpeed: currentWindSpeed,
      currentHumidity: currentHumidity,
      currentDescription: currentDescription,
      currentIconCode: currentIconCode,
      daily: dailyForecasts,
    );
  }

  /// Maps WMO weather codes to OpenWeatherMap icon codes.
  /// See: https://open-meteo.com/en/docs
  static String _wmoCodeToIcon(int code, bool isDay) {
    final d = isDay ? 'd' : 'n';
    if (code == 0) return '01$d'; // Clear sky
    if (code <= 2) return '02$d'; // Partly cloudy
    if (code == 3) return '03$d'; // Overcast
    if (code <= 49) return '50$d'; // Fog
    if (code <= 59) return '09$d'; // Drizzle
    if (code <= 69) return '10$d'; // Rain
    if (code <= 79) return '13$d'; // Snow
    if (code <= 84) return '09$d'; // Rain showers
    if (code <= 86) return '13$d'; // Snow showers
    if (code <= 99) return '11$d'; // Thunderstorm
    return '01$d';
  }

  /// Maps WMO weather codes to Bengali descriptions.
  static String _wmoCodeToDescription(int code) {
    if (code == 0) return 'পরিষ্কার আকাশ';
    if (code == 1) return 'প্রধানত পরিষ্কার';
    if (code == 2) return 'আংশিক মেঘলা';
    if (code == 3) return 'মেঘলা';
    if (code <= 49) return 'কুয়াশা';
    if (code <= 59) return 'গুঁড়ি গুঁড়ি বৃষ্টি';
    if (code <= 69) return 'বৃষ্টি';
    if (code <= 79) return 'তুষারপাত';
    if (code <= 84) return 'বৃষ্টির ঝরনা';
    if (code <= 86) return 'তুষার ঝরনা';
    if (code <= 99) return 'বজ্রবৃষ্টি';
    return 'পরিষ্কার আকাশ';
  }

  // ---------------------------------------------------------------------------
  // Demo / mock weather data – mirrors Bangladesh pre-monsoon conditions
  // ---------------------------------------------------------------------------

  /// Public accessor used by [WeatherProvider] constructor to seed the UI
  /// immediately before any real API call completes.
  static WeatherData getDemoData() => _demoWeatherData();

  /// Returns realistic sample weather data for Bangladesh so the UI is
  /// always populated even without a real API key or internet connection.
  static WeatherData _demoWeatherData() {
    final now = DateTime.now();
    final icons = ['04d', '10d', '09d', '11d', '10d', '02d', '01d'];
    final descs = [
      'overcast clouds',
      'moderate rain',
      'light rain',
      'thunderstorm',
      'light rain',
      'few clouds',
      'clear sky',
    ];
    final maxTemps = [33.0, 30.0, 28.0, 27.0, 29.0, 32.0, 34.0];
    final minTemps = [26.0, 24.0, 23.0, 22.0, 24.0, 25.0, 26.0];
    final winds = [22.0, 35.0, 28.0, 55.0, 18.0, 12.0, 10.0]; // km/h
    final humidities = [85.0, 90.0, 92.0, 88.0, 82.0, 75.0, 70.0];
    final rains = [0.0, 12.0, 5.0, 20.0, 3.0, 0.0, 0.0];

    final daily = List.generate(7, (i) {
      return DayForecast(
        date: now.add(Duration(days: i)),
        tempMin: minTemps[i],
        tempMax: maxTemps[i],
        humidity: humidities[i],
        windSpeed: winds[i],
        description: descs[i],
        iconCode: icons[i],
        precipitation: rains[i],
      );
    });

    return WeatherData(
      currentTemp: 32.0,
      currentWindSpeed: 22.0,
      currentHumidity: 85.0,
      currentDescription: 'overcast clouds',
      currentIconCode: '04d',
      daily: daily,
      isDemo: true, // Mark as demo data - NEVER cache this!
    );
  }

  // ---------------------------------------------------------------------------
  // Warning level helpers
  // ---------------------------------------------------------------------------

  /// Maps a wind speed (km/h) to the Bangladesh Meteorological Department
  /// cyclone warning signal number (0 = no signal / safe, 1–10 = BMD signals).
  static int calculateWarningLevel(double windSpeedKmh) {
    if (windSpeedKmh < 40) return 0; // Safe – no warning signal
    if (windSpeedKmh < 51) return 1; // Signal 1 – distant caution  (40–50)
    if (windSpeedKmh < 62) return 2; // Signal 2 – distant warning  (51–61)
    if (windSpeedKmh < 71) return 4; // Signal 4 – local warning    (62–70)
    if (windSpeedKmh < 81) return 5; // Signal 5 – danger           (71–80)
    if (windSpeedKmh < 91) return 6; // Signal 6 – big danger       (81–90)
    if (windSpeedKmh < 111) return 7; // Signal 7 – great danger    (91–110)
    if (windSpeedKmh < 121) return 8; // Signal 8 – catastrophic    (111–120)
    if (windSpeedKmh < 151) return 9; // Signal 9 – extreme         (121–150)
    return 10; // Signal 10 – super-cyclone (≥151)
  }

  /// Returns a short human-readable description for a given warning level
  /// (0 = safe, 1–10 = BMD warning signals).
  static String warningDescription(int level) {
    if (level == 0) return 'আবহাওয়া স্বাভাবিক। কোনো সংকেত নেই।';
    if (level <= 2) return 'সাধারণ সতর্কতা। আবহাওয়ার খবর অনুসরণ করুন।';
    if (level <= 4) return 'স্থানীয় হুঁশিয়ারি সংকেত। সতর্ক থাকুন।';
    if (level <= 6) return 'বিপদ সংকেত! ঝড় আসছে। আশ্রয়ের প্রস্তুতি নিন।';
    if (level <= 8) return 'মহাবিপদ সংকেত! অবিলম্বে আশ্রয়ে যান।';
    return 'সর্বোচ্চ বিপদ! সুপার সাইক্লোন। বের হবেন না।';
  }

  /// Returns the background colour associated with a warning level.
  static int warningColor(int level) {
    if (level <= 2) return 0xFF4CAF50; // green
    if (level <= 4) return 0xFFFF9800; // orange
    if (level <= 7) return 0xFFFF5722; // deep-orange
    return 0xFFB71C1C; // dark red
  }
}
