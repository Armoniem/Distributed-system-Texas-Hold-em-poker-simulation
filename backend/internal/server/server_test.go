package server

import (
	"context"
	"testing"

	"log/slog"
	"os"

	pb "github.com/armoniem/pokereval/backend/gen/pokereval"
)

var srv *PokerServer

func init() {
	srv = New(slog.New(slog.NewTextHandler(os.Stderr, nil)))
}

// ─────────────────────────────────────────────────────────────────────────────
// EvaluateHand tests
// ─────────────────────────────────────────────────────────────────────────────

func TestEvaluateHand_RoyalFlush(t *testing.T) {
	resp, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"HA", "HK"},
		CommunityCards: []string{"HQ", "HJ", "HT", "D2", "C3"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Category != "Royal Flush" {
		t.Errorf("expected Royal Flush, got %q", resp.Category)
	}
}

func TestEvaluateHand_StraightFlush(t *testing.T) {
	resp, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"H9", "H8"},
		CommunityCards: []string{"H7", "H6", "H5", "D2", "CA"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Category != "Straight Flush" {
		t.Errorf("expected Straight Flush, got %q", resp.Category)
	}
}

func TestEvaluateHand_FourOfAKind(t *testing.T) {
	resp, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"HA", "SA"},
		CommunityCards: []string{"DA", "CA", "H2", "D3", "C5"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Category != "Four of a Kind" {
		t.Errorf("expected Four of a Kind, got %q", resp.Category)
	}
}

func TestEvaluateHand_FullHouse(t *testing.T) {
	resp, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"HA", "SA"},
		CommunityCards: []string{"DA", "HK", "SK", "D7", "C9"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Category != "Full House" {
		t.Errorf("expected Full House, got %q", resp.Category)
	}
}

func TestEvaluateHand_AceLowStraight(t *testing.T) {
	resp, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"HA", "H2"},
		CommunityCards: []string{"D3", "C4", "S5", "HK", "DQ"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Category != "Straight" {
		t.Errorf("expected Straight (ace-low), got %q", resp.Category)
	}
}

func TestEvaluateHand_HighCard(t *testing.T) {
	resp, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"H2", "S4"},
		CommunityCards: []string{"D6", "C8", "HT", "DJ", "SQ"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Category != "High Card" {
		t.Errorf("expected High Card, got %q", resp.Category)
	}
}

func TestEvaluateHand_InvalidCardCount(t *testing.T) {
	_, err := srv.EvaluateHand(context.Background(), &pb.EvaluateHandRequest{
		HoleCards:      []string{"HA"},
		CommunityCards: []string{"HQ", "HJ", "HT", "D2", "C3"},
	})
	if err == nil {
		t.Fatal("expected error for wrong hole card count, got nil")
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// CompareHands tests
// ─────────────────────────────────────────────────────────────────────────────

func TestCompareHands_Player1Wins(t *testing.T) {
	resp, err := srv.CompareHands(context.Background(), &pb.CompareHandsRequest{
		HoleCards1:      []string{"HA", "HK"},
		CommunityCards1: []string{"HQ", "HJ", "HT", "D2", "C3"},
		HoleCards2:      []string{"D2", "C9"},
		CommunityCards2: []string{"HQ", "HJ", "HT", "S5", "D6"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Winner != "player1" {
		t.Errorf("expected player1 to win, got %q", resp.Winner)
	}
}

func TestCompareHands_Draw(t *testing.T) {
	// Same 5 community cards, same hand for both players
	resp, err := srv.CompareHands(context.Background(), &pb.CompareHandsRequest{
		HoleCards1:      []string{"H2", "S2"},
		CommunityCards1: []string{"HA", "HK", "HQ", "HJ", "HT"},
		HoleCards2:      []string{"D2", "C2"},
		CommunityCards2: []string{"HA", "HK", "HQ", "HJ", "HT"},
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.Winner != "draw" {
		t.Errorf("expected draw, got %q (hand1=%s, hand2=%s)", resp.Winner, resp.Hand1.Category, resp.Hand2.Category)
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// CalculateWinProbability tests
// ─────────────────────────────────────────────────────────────────────────────

func TestWinProbability_PocketAcesHeadsUp(t *testing.T) {
	resp, err := srv.CalculateWinProbability(context.Background(), &pb.ProbabilityRequest{
		HoleCards:      []string{"HA", "SA"},
		CommunityCards: []string{},
		NumPlayers:     2,
		NumSimulations: 5000,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// Pocket aces should win >70% heads-up
	if resp.WinProbability < 70.0 {
		t.Errorf("expected pocket aces to win >70%%, got %.2f%%", resp.WinProbability)
	}
}

func TestWinProbability_InvalidPlayerCount(t *testing.T) {
	_, err := srv.CalculateWinProbability(context.Background(), &pb.ProbabilityRequest{
		HoleCards:      []string{"HA", "SA"},
		CommunityCards: []string{},
		NumPlayers:     1,
		NumSimulations: 100,
	})
	if err == nil {
		t.Fatal("expected error for num_players=1, got nil")
	}
}

func TestWinProbability_Flop(t *testing.T) {
	// Known strong hand on the flop
	resp, err := srv.CalculateWinProbability(context.Background(), &pb.ProbabilityRequest{
		HoleCards:      []string{"HA", "SA"},
		CommunityCards: []string{"DA", "CA", "H2"},
		NumPlayers:     2,
		NumSimulations: 2000,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	// Four aces should win nearly all the time
	if resp.WinProbability < 95.0 {
		t.Errorf("expected four aces to win >95%%, got %.2f%%", resp.WinProbability)
	}
}
