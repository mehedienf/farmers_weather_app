import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _baseUrl = "https://flicksize.com/krishi_plus/";

/// Manages subscription status checks with caching and API call tracking
/// to prevent rate limiting and API exhaustion.
class SubscriptionService {
  static const String _cacheKeyStatus = 'cached_subscription_status';
  static const String _cacheKeyTimestamp = 'cached_subscription_timestamp';
  static const String _cacheKeyApiCount = 'api_call_count';
  static const String _cacheKeyApiResetTime = 'api_reset_time';

  // Cache subscription status for 5 minutes
  static const int _cacheDurationSeconds = 300;

  // API call limits: max 20 calls per hour to be safe
  static const int _maxApiCallsPerHour = 20;
  static const int _apiResetDurationSeconds = 3600;

  /// Check subscription status with caching and rate limiting
  Future<SubscriptionCheckResult> checkSubscription(String phone) async {
    // Note: cached status handled by _getCachedStatus which accesses SharedPreferences
    // Check if we have a valid cached result
    final cachedResult = await _getCachedStatus(phone);
    if (cachedResult != null) {
      return SubscriptionCheckResult(
        isSubscribed: cachedResult,
        fromCache: true,
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    }

    // Check API call limit before making a request
    final canMakeApiCall = await _canMakeApiCall();
    if (!canMakeApiCall) {
      return SubscriptionCheckResult(
        isSubscribed: false,
        fromCache: false,
        rateLimited: true,
        apiCallsRemaining: 0,
      );
    }

    // Make the API call
    try {
      await _incrementApiCallCount();

      final response = await http.post(
        Uri.parse('$_baseUrl/check_subscription.php'),
        body: {'user_mobile': phone},
      );

      if (response.statusCode != 200) {
        return SubscriptionCheckResult(
          isSubscribed: false,
          fromCache: false,
          error: 'HTTP ${response.statusCode}',
          apiCallsRemaining: await _getRemainingApiCalls(),
        );
      }

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return SubscriptionCheckResult(
          isSubscribed: false,
          fromCache: false,
          error: 'Invalid JSON response',
          apiCallsRemaining: await _getRemainingApiCalls(),
        );
      }

      if (decoded is! Map<String, dynamic>) {
        return SubscriptionCheckResult(
          isSubscribed: false,
          fromCache: false,
          error: 'Unexpected response format',
          apiCallsRemaining: await _getRemainingApiCalls(),
        );
      }

      final isSubscribed = _isSubscribedFromResponse(decoded);

      // Cache the result
      await _cacheStatus(phone, isSubscribed);

      return SubscriptionCheckResult(
        isSubscribed: isSubscribed,
        fromCache: false,
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    } catch (e) {
      return SubscriptionCheckResult(
        isSubscribed: false,
        fromCache: false,
        error: e.toString(),
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    }
  }

  /// Send OTP with rate limiting
  Future<OtpSendResult> sendOtp(String phone) async {
    // Check API call limit
    final canMakeApiCall = await _canMakeApiCall();
    if (!canMakeApiCall) {
      return OtpSendResult(
        success: false,
        rateLimited: true,
        message: 'Too many API requests. Please wait.',
        apiCallsRemaining: 0,
      );
    }

    try {
      await _incrementApiCallCount();

      final response = await http.post(
        Uri.parse('$_baseUrl/send_otp.php'),
        body: {'user_mobile': phone},
      );

      final dynamic parsed = jsonDecode(response.body);
      if (parsed is! Map<String, dynamic>) {
        return OtpSendResult(
          success: false,
          message: 'Invalid response format',
          apiCallsRemaining: await _getRemainingApiCalls(),
        );
      }

      final otpData = parsed;
      final success = otpData['success'] == true;
      final referenceNo = otpData['referenceNo']?.toString() ?? '';
      final message =
          otpData['message']?.toString() ??
          otpData['statusDetail']?.toString() ??
          '';

      return OtpSendResult(
        success: success && referenceNo.isNotEmpty,
        referenceNo: referenceNo,
        message: message,
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    } catch (e) {
      return OtpSendResult(
        success: false,
        message: e.toString(),
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    }
  }

  /// Verify OTP with extended sync wait
  Future<OtpVerifyResult> verifyOtp(
    String otp,
    String referenceNo,
    String phone,
  ) async {
    // Check API call limit
    final canMakeApiCall = await _canMakeApiCall();
    if (!canMakeApiCall) {
      return OtpVerifyResult(
        success: false,
        rateLimited: true,
        message: 'Too many API requests. Please wait.',
        apiCallsRemaining: 0,
      );
    }

    try {
      await _incrementApiCallCount();

      final response = await http.post(
        Uri.parse('$_baseUrl/verify_otp.php'),
        body: {'Otp': otp, 'referenceNo': referenceNo, 'user_mobile': phone},
      );

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = response.body;
      }

      final data = parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{};

      final statusCode =
          data['statusCode']?.toString().trim().toUpperCase() ?? '';
      final statusDetail = data['statusDetail']?.toString().trim() ?? '';

      if (statusCode != 'S1000') {
        return OtpVerifyResult(
          success: false,
          message: statusDetail.isNotEmpty ? statusDetail : 'Invalid OTP',
          apiCallsRemaining: await _getRemainingApiCalls(),
        );
      }

      // OTP verified successfully - wait briefly for subscription sync.
      final subscriptionActive = await _waitForSubscriptionSync(
        phone,
        attempts: 5,
      );

      if (subscriptionActive) {
        // Clear old cache and cache the new status
        await _cacheStatus(phone, true);
      }

      return OtpVerifyResult(
        success: subscriptionActive,
        message: subscriptionActive
            ? 'Subscription activated'
            : statusDetail.isNotEmpty
            ? statusDetail
            : 'OTP verified but subscription not active yet',
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    } catch (e) {
      return OtpVerifyResult(
        success: false,
        message: e.toString(),
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    }
  }

  /// Invalidate cached subscription status
  Future<void> invalidateCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKeyStatus);
    await prefs.remove(_cacheKeyTimestamp);
  }

  /// Get remaining API calls in current window
  Future<int> _getRemainingApiCalls() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_cacheKeyApiCount) ?? 0;
    return (_maxApiCallsPerHour - count).clamp(0, _maxApiCallsPerHour);
  }

  /// Check if we can make an API call without hitting rate limit
  Future<bool> _canMakeApiCall() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset the counter
    final resetTime = prefs.getInt(_cacheKeyApiResetTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (now >= resetTime) {
      // Reset counter
      await prefs.setInt(_cacheKeyApiCount, 0);
      await prefs.setInt(_cacheKeyApiResetTime, now + _apiResetDurationSeconds);
      return true;
    }

    // Check current count
    final count = prefs.getInt(_cacheKeyApiCount) ?? 0;
    return count < _maxApiCallsPerHour;
  }

  /// Increment API call counter
  Future<void> _incrementApiCallCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_cacheKeyApiCount) ?? 0;
    await prefs.setInt(_cacheKeyApiCount, count + 1);

    // Set reset time if not set
    final resetTime = prefs.getInt(_cacheKeyApiResetTime) ?? 0;
    if (resetTime == 0) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await prefs.setInt(_cacheKeyApiResetTime, now + _apiResetDurationSeconds);
    }
  }

  /// Get cached subscription status if valid
  Future<bool?> _getCachedStatus(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedPhone = prefs.getString('userPhone') ?? '';

    // Only use cache if it's for the same phone number
    if (cachedPhone != phone) {
      return null;
    }

    final timestamp = prefs.getInt(_cacheKeyTimestamp) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (now - timestamp > _cacheDurationSeconds) {
      // Cache expired
      return null;
    }

    return prefs.getBool(_cacheKeyStatus);
  }

  /// Cache subscription status
  Future<void> _cacheStatus(String phone, bool isSubscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheKeyStatus, isSubscribed);
    await prefs.setInt(
      _cacheKeyTimestamp,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// Wait for subscription to sync after OTP verification
  Future<bool> _waitForSubscriptionSync(
    String phone, {
    int attempts = 5,
  }) async {
    for (var i = 0; i < attempts; i++) {
      // Don't count these checks against rate limit as they're critical
      final result = await _checkSubscriptionDirect(phone);
      if (result) {
        return true;
      }
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  /// Direct subscription check (bypasses cache, used only for sync polling)
  Future<bool> _checkSubscriptionDirect(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/check_subscription.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;

      return _isSubscribedFromResponse(decoded);
    } catch (_) {
      return false;
    }
  }

  /// Unsubscribe the given phone number from service.
  /// Returns a result with success flag and an optional message.
  Future<UnsubscribeResult> unsubscribe(String phone) async {
    // Check API call limit
    final canMakeApiCall = await _canMakeApiCall();
    if (!canMakeApiCall) {
      return UnsubscribeResult(
        success: false,
        message: 'Too many API requests. Please wait.',
        apiCallsRemaining: 0,
      );
    }

    try {
      await _incrementApiCallCount();

      final response = await http.post(
        Uri.parse('$_baseUrl/unsubscribe.php'),
        body: {'user_mobile': phone},
      );

      if (response.statusCode != 200) {
        return UnsubscribeResult(
          success: false,
          message: 'HTTP ${response.statusCode}',
          apiCallsRemaining: await _getRemainingApiCalls(),
        );
      }

      dynamic parsed;
      try {
        parsed = jsonDecode(response.body);
      } catch (_) {
        parsed = response.body;
      }

      final data = parsed is Map<String, dynamic>
          ? parsed
          : <String, dynamic>{};

      // Common success signals: explicit success flag or statusCode == S1000
      final success =
          data['success'] == true ||
          (data['statusCode']?.toString().trim().toUpperCase() == 'S1000');

      final message =
          data['message']?.toString() ??
          data['statusDetail']?.toString() ??
          (success ? 'Unsubscribed' : 'Unsubscribe failed');

      return UnsubscribeResult(
        success: success,
        message: message,
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    } catch (e) {
      return UnsubscribeResult(
        success: false,
        message: e.toString(),
        apiCallsRemaining: await _getRemainingApiCalls(),
      );
    }
  }

  /// Parse subscription status from API response
  bool _isSubscribedFromResponse(Map<String, dynamic> data) {
    final status =
        data['subscriptionStatus']?.toString().trim().toUpperCase() ?? '';
    final isSubscribed = data['isSubscribed'];

    if (status == 'REGISTERED') return true;
    if (isSubscribed == true || isSubscribed == 'true') return true;

    return false;
  }
}

/// Result of subscription check
class SubscriptionCheckResult {
  final bool isSubscribed;
  final bool fromCache;
  final bool rateLimited;
  final String? error;
  final int apiCallsRemaining;

  SubscriptionCheckResult({
    required this.isSubscribed,
    this.fromCache = false,
    this.rateLimited = false,
    this.error,
    required this.apiCallsRemaining,
  });
}

/// Result of OTP send request
class OtpSendResult {
  final bool success;
  final String? referenceNo;
  final String? message;
  final bool rateLimited;
  final int apiCallsRemaining;

  OtpSendResult({
    required this.success,
    this.referenceNo,
    this.message,
    this.rateLimited = false,
    required this.apiCallsRemaining,
  });
}

/// Result of OTP verification
class OtpVerifyResult {
  final bool success;
  final String? message;
  final bool rateLimited;
  final int apiCallsRemaining;

  OtpVerifyResult({
    required this.success,
    this.message,
    this.rateLimited = false,
    required this.apiCallsRemaining,
  });
}

/// Result of an unsubscribe call
class UnsubscribeResult {
  final bool success;
  final String? message;
  final bool rateLimited;
  final int apiCallsRemaining;

  UnsubscribeResult({
    required this.success,
    this.message,
    this.rateLimited = false,
    required this.apiCallsRemaining,
  });
}
