import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

// ─── Domain Models ──────────────────────────────────────────────────────────

class EvaluateHandResponse {
  final List<String> bestHand;
  final String category;
  final int strength;

  EvaluateHandResponse({
    required this.bestHand,
    required this.category,
    required this.strength,
  });

  factory EvaluateHandResponse.fromJson(Map<String, dynamic> j) =>
      EvaluateHandResponse(
        bestHand: List<String>.from(j['best_hand'] ?? []),
        category: j['category'] ?? '',
        strength: (j['strength'] ?? 0) is int
            ? j['strength']
            : int.tryParse(j['strength'].toString()) ?? 0,
      );
}

class CompareHandsResponse {
  final EvaluateHandResponse hand1;
  final EvaluateHandResponse hand2;
  final String winner;

  CompareHandsResponse({
    required this.hand1,
    required this.hand2,
    required this.winner,
  });

  factory CompareHandsResponse.fromJson(Map<String, dynamic> j) =>
      CompareHandsResponse(
        hand1: EvaluateHandResponse.fromJson(j['hand1'] ?? {}),
        hand2: EvaluateHandResponse.fromJson(j['hand2'] ?? {}),
        winner: j['winner'] ?? 'draw',
      );
}

class ProbabilityResponse {
  final double winProbability;
  final double drawProbability;
  final int simulationsRun;
  final int winCount;
  final int drawCount;

  ProbabilityResponse({
    required this.winProbability,
    required this.drawProbability,
    required this.simulationsRun,
    required this.winCount,
    required this.drawCount,
  });

  factory ProbabilityResponse.fromJson(Map<String, dynamic> j) =>
      ProbabilityResponse(
        winProbability: (j['win_probability'] ?? 0.0).toDouble(),
        drawProbability: (j['draw_probability'] ?? 0.0).toDouble(),
        simulationsRun: (j['simulations_run'] ?? 0) is int
            ? j['simulations_run']
            : int.tryParse(j['simulations_run'].toString()) ?? 0,
        winCount: (j['win_count'] ?? 0) is int
            ? j['win_count']
            : int.tryParse(j['win_count'].toString()) ?? 0,
        drawCount: (j['draw_count'] ?? 0) is int
            ? j['draw_count']
            : int.tryParse(j['draw_count'].toString()) ?? 0,
      );

  double get lossPercent => 100.0 - winProbability - drawProbability;
}

// ─── API Client ────────────────────────────────────────────────────────────

class ApiClient {
  final http.Client _http;
  final Duration timeout;

  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 60)})
    : _http = client ?? http.Client();

  String get _base => AppConfig.backendUrl;

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$_base/$path');
    final resp = await _http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200) {
      throw ApiException(
        decoded['message'] ?? 'Request failed',
        statusCode: resp.statusCode,
      );
    }
    return decoded;
  }

  Future<String> health() async {
    final uri = Uri.parse('$_base/healthz');
    final resp = await _http.get(uri).timeout(const Duration(seconds: 5));
    if (resp.statusCode == 200) return 'Healthy';
    throw ApiException('Backend unhealthy', statusCode: resp.statusCode);
  }

  Future<EvaluateHandResponse> evaluateHand({
    required List<String> holeCards,
    required List<String> communityCards,
  }) async {
    final data = await _post('pokereval.PokerEval/EvaluateHand', {
      'hole_cards': holeCards,
      'community_cards': communityCards,
    });
    return EvaluateHandResponse.fromJson(data);
  }

  Future<CompareHandsResponse> compareHands({
    required List<String> hole1,
    required List<String> community1,
    required List<String> hole2,
    required List<String> community2,
  }) async {
    final data = await _post('pokereval.PokerEval/CompareHands', {
      'hole_cards_1': hole1,
      'community_cards_1': community1,
      'hole_cards_2': hole2,
      'community_cards_2': community2,
    });
    return CompareHandsResponse.fromJson(data);
  }

  Future<ProbabilityResponse> calculateProbability({
    required List<String> holeCards,
    required List<String> communityCards,
    required int numPlayers,
    required int numSimulations,
  }) async {
    final data = await _post('pokereval.PokerEval/CalculateWinProbability', {
      'hole_cards': holeCards,
      'community_cards': communityCards,
      'num_players': numPlayers,
      'num_simulations': numSimulations,
    });
    return ProbabilityResponse.fromJson(data);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, {this.statusCode = 500});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ─── ApiProvider ───────────────────────────────────────────────────────────

enum ApiStatus { idle, loading, success, error }

class ApiProvider extends ChangeNotifier {
  final ApiClient _client = ApiClient();

  // Evaluate
  ApiStatus evaluateStatus = ApiStatus.idle;
  EvaluateHandResponse? evaluateResult;
  String? evaluateError;

  // Compare
  ApiStatus compareStatus = ApiStatus.idle;
  CompareHandsResponse? compareResult;
  String? compareError;

  // Probability
  ApiStatus probabilityStatus = ApiStatus.idle;
  ProbabilityResponse? probabilityResult;
  String? probabilityError;

  // Health
  ApiStatus healthStatus = ApiStatus.idle;
  String? healthResult;
  String? healthError;
  DateTime? lastHealthCheck;
  Duration? lastLatency;

  Future<void> evaluateHand(List<String> hole, List<String> community) async {
    evaluateStatus = ApiStatus.loading;
    evaluateError = null;
    notifyListeners();
    try {
      evaluateResult = await _client.evaluateHand(
        holeCards: hole,
        communityCards: community,
      );
      evaluateStatus = ApiStatus.success;
    } on ApiException catch (e) {
      evaluateError = e.message;
      evaluateStatus = ApiStatus.error;
    } catch (e) {
      evaluateError = e.toString();
      evaluateStatus = ApiStatus.error;
    }
    notifyListeners();
  }

  Future<void> compareHands(
    List<String> h1,
    List<String> c1,
    List<String> h2,
    List<String> c2,
  ) async {
    compareStatus = ApiStatus.loading;
    compareError = null;
    notifyListeners();
    try {
      compareResult = await _client.compareHands(
        hole1: h1,
        community1: c1,
        hole2: h2,
        community2: c2,
      );
      compareStatus = ApiStatus.success;
    } on ApiException catch (e) {
      compareError = e.message;
      compareStatus = ApiStatus.error;
    } catch (e) {
      compareError = e.toString();
      compareStatus = ApiStatus.error;
    }
    notifyListeners();
  }

  Future<void> calculateProbability(
    List<String> hole,
    List<String> community,
    int players,
    int sims,
  ) async {
    probabilityStatus = ApiStatus.loading;
    probabilityError = null;
    notifyListeners();
    try {
      probabilityResult = await _client.calculateProbability(
        holeCards: hole,
        communityCards: community,
        numPlayers: players,
        numSimulations: sims,
      );
      probabilityStatus = ApiStatus.success;
    } on ApiException catch (e) {
      probabilityError = e.message;
      probabilityStatus = ApiStatus.error;
    } catch (e) {
      probabilityError = e.toString();
      probabilityStatus = ApiStatus.error;
    }
    notifyListeners();
  }

  Future<void> checkHealth() async {
    healthStatus = ApiStatus.loading;
    healthError = null;
    notifyListeners();
    final sw = Stopwatch()..start();
    try {
      healthResult = await _client.health();
      healthStatus = ApiStatus.success;
    } on ApiException catch (e) {
      healthError = e.message;
      healthStatus = ApiStatus.error;
    } catch (e) {
      healthError = 'Cannot reach backend: ${e.toString()}';
      healthStatus = ApiStatus.error;
    }
    sw.stop();
    lastLatency = sw.elapsed;
    lastHealthCheck = DateTime.now();
    notifyListeners();
  }
}
