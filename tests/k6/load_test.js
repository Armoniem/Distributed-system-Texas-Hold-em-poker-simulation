import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// ─── Configuration ────────────────────────────────────────────────────────────

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

// Custom metrics
const errorRate = new Rate('errors');
const evaluateTrend = new Trend('evaluate_hand_duration');
const compareTrend  = new Trend('compare_hands_duration');
const probTrend     = new Trend('probability_duration');

export const options = {
  scenarios: {
    // Ramp-up load test for EvaluateHand
    evaluate_ramp: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '30s', target: 20 },
        { duration: '60s', target: 50 },
        { duration: '30s', target: 0 },
      ],
      exec: 'evaluateHand',
    },
    // Steady load for CompareHands
    compare_steady: {
      executor: 'constant-vus',
      vus: 10,
      duration: '2m',
      exec: 'compareHands',
      startTime: '30s',
    },
    // Spike test for Monte Carlo
    probability_spike: {
      executor: 'ramping-vus',
      startVUs: 1,
      stages: [
        { duration: '20s', target: 5 },
        { duration: '40s', target: 15 },
        { duration: '20s', target: 1 },
      ],
      exec: 'calculateProbability',
      startTime: '1m',
    },
  },
  thresholds: {
    'http_req_duration{scenario:evaluate_ramp}': ['p(95)<500'],
    'http_req_duration{scenario:compare_steady}': ['p(95)<500'],
    'http_req_duration{scenario:probability_spike}': ['p(95)<8000'],
    'errors': ['rate<0.05'],
  },
};

const HEADERS = { 'Content-Type': 'application/json' };

// ─── Scenario: EvaluateHand ───────────────────────────────────────────────────

export function evaluateHand() {
  const payload = JSON.stringify({
    hole_cards: ['HA', 'SK'],
    community_cards: ['HQ', 'HJ', 'HT', 'D2', 'C3'],
  });

  const res = http.post(`${BASE_URL}/pokereval.PokerEval/EvaluateHand`, payload, { headers: HEADERS });

  const ok = check(res, {
    'status 200': r => r.status === 200,
    'has category': r => JSON.parse(r.body).category !== undefined,
    'has best_hand': r => JSON.parse(r.body).best_hand !== undefined,
  });

  errorRate.add(!ok);
  evaluateTrend.add(res.timings.duration);
  sleep(0.1);
}

// ─── Scenario: CompareHands ───────────────────────────────────────────────────

export function compareHands() {
  const payload = JSON.stringify({
    hole_cards_1: ['HA', 'SK'],
    community_cards_1: ['HQ', 'HJ', 'HT', 'D2', 'C3'],
    hole_cards_2: ['D9', 'C8'],
    community_cards_2: ['HQ', 'HJ', 'HT', 'D4', 'C5'],
  });

  const res = http.post(`${BASE_URL}/pokereval.PokerEval/CompareHands`, payload, { headers: HEADERS });

  const ok = check(res, {
    'status 200': r => r.status === 200,
    'has winner': r => ['player1', 'player2', 'draw'].includes(JSON.parse(r.body).winner),
  });

  errorRate.add(!ok);
  compareTrend.add(res.timings.duration);
  sleep(0.1);
}

// ─── Scenario: CalculateWinProbability ───────────────────────────────────────

export function calculateProbability() {
  const payload = JSON.stringify({
    hole_cards: ['HA', 'SA'],
    community_cards: [],
    num_players: 3,
    num_simulations: 5000,
  });

  const res = http.post(`${BASE_URL}/pokereval.PokerEval/CalculateWinProbability`, payload, { headers: HEADERS });

  const ok = check(res, {
    'status 200': r => r.status === 200,
    'win_probability in range': r => {
      const body = JSON.parse(r.body);
      return body.win_probability >= 0 && body.win_probability <= 100;
    },
    'simulations_run > 0': r => JSON.parse(r.body).simulations_run > 0,
  });

  errorRate.add(!ok);
  probTrend.add(res.timings.duration);
  sleep(0.5);
}

// ─── Health check (default scenario) ─────────────────────────────────────────

export default function () {
  const res = http.get(`${BASE_URL}/healthz`);
  check(res, {
    'health 200': r => r.status === 200,
    'health ok': r => JSON.parse(r.body).status === 'ok',
  });
  sleep(1);
}
