// Package server wires the poker domain logic to the gRPC service interface.
package server

import (
	"context"
	"fmt"
	"log/slog"

	pb "github.com/armoniem/pokereval/backend/gen/pokereval"
	"github.com/armoniem/pokereval/backend/internal/poker"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// PokerServer implements PokerEvalServer.
type PokerServer struct {
	pb.UnimplementedPokerEvalServer
	log *slog.Logger
}

// New creates a new PokerServer.
func New(log *slog.Logger) *PokerServer {
	return &PokerServer{log: log}
}

// ─────────────────────────────────────────────────────────────────────────────
// EvaluateHand
// ─────────────────────────────────────────────────────────────────────────────

func (s *PokerServer) EvaluateHand(_ context.Context, req *pb.EvaluateHandRequest) (*pb.EvaluateHandResponse, error) {
	if len(req.HoleCards) != 2 {
		return nil, status.Errorf(codes.InvalidArgument, "hole_cards must contain exactly 2 cards, got %d", len(req.HoleCards))
	}
	if len(req.CommunityCards) != 5 {
		return nil, status.Errorf(codes.InvalidArgument, "community_cards must contain exactly 5 cards, got %d", len(req.CommunityCards))
	}

	all := append(req.HoleCards, req.CommunityCards...)
	cards, err := poker.ParseCards(all)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "card parse error: %v", err)
	}

	result := poker.EvaluateBestHand(cards)
	s.log.Info("EvaluateHand", "category", result.Category, "strength", result.Strength)
	return &pb.EvaluateHandResponse{
		BestHand: poker.CardsToStrings(result.Cards),
		Category: result.Category,
		Strength: result.Strength,
	}, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// CompareHands
// ─────────────────────────────────────────────────────────────────────────────

func (s *PokerServer) CompareHands(_ context.Context, req *pb.CompareHandsRequest) (*pb.CompareHandsResponse, error) {
	if err := validateHandSpec("player1", req.HoleCards1, req.CommunityCards1); err != nil {
		return nil, err
	}
	if err := validateHandSpec("player2", req.HoleCards2, req.CommunityCards2); err != nil {
		return nil, err
	}

	cards1, err := poker.ParseCards(append(req.HoleCards1, req.CommunityCards1...))
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "player1 card error: %v", err)
	}
	cards2, err := poker.ParseCards(append(req.HoleCards2, req.CommunityCards2...))
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "player2 card error: %v", err)
	}

	r1 := poker.EvaluateBestHand(cards1)
	r2 := poker.EvaluateBestHand(cards2)

	winner := "draw"
	if r1.Strength > r2.Strength {
		winner = "player1"
	} else if r2.Strength > r1.Strength {
		winner = "player2"
	}

	s.log.Info("CompareHands", "hand1", r1.Category, "hand2", r2.Category, "winner", winner)
	return &pb.CompareHandsResponse{
		Hand1: &pb.EvaluateHandResponse{
			BestHand: poker.CardsToStrings(r1.Cards),
			Category: r1.Category,
			Strength: r1.Strength,
		},
		Hand2: &pb.EvaluateHandResponse{
			BestHand: poker.CardsToStrings(r2.Cards),
			Category: r2.Category,
			Strength: r2.Strength,
		},
		Winner: winner,
	}, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// CalculateWinProbability
// ─────────────────────────────────────────────────────────────────────────────

func (s *PokerServer) CalculateWinProbability(_ context.Context, req *pb.ProbabilityRequest) (*pb.ProbabilityResponse, error) {
	if len(req.HoleCards) != 2 {
		return nil, status.Errorf(codes.InvalidArgument, "hole_cards must contain exactly 2 cards")
	}
	commLen := len(req.CommunityCards)
	if commLen != 0 && commLen != 3 && commLen != 4 && commLen != 5 {
		return nil, status.Errorf(codes.InvalidArgument,
			"community_cards must have 0, 3, 4, or 5 cards, got %d", commLen)
	}
	if req.NumPlayers < 2 || req.NumPlayers > 9 {
		return nil, status.Errorf(codes.InvalidArgument, "num_players must be 2–9")
	}
	numSims := int(req.NumSimulations)
	if numSims < 1 {
		numSims = 1000
	}
	if numSims > 100_000 {
		numSims = 100_000
	}

	holecards, err := poker.ParseCards(req.HoleCards)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "hole card error: %v", err)
	}
	community, err := poker.ParseCards(req.CommunityCards)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "community card error: %v", err)
	}

	result := poker.MonteCarloSimulate(holecards, community, int(req.NumPlayers), numSims)
	winPct := 100.0 * float64(result.Wins) / float64(result.Total)
	drawPct := 100.0 * float64(result.Draws) / float64(result.Total)

	s.log.Info("CalculateWinProbability",
		"numPlayers", req.NumPlayers,
		"numSims", result.Total,
		"winPct", fmt.Sprintf("%.2f%%", winPct),
	)
	return &pb.ProbabilityResponse{
		WinProbability:  winPct,
		DrawProbability: drawPct,
		SimulationsRun:  int32(result.Total),
		WinCount:        result.Wins,
		DrawCount:       result.Draws,
	}, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

func validateHandSpec(label string, hole, community []string) error {
	if len(hole) != 2 {
		return status.Errorf(codes.InvalidArgument, "%s: hole_cards must have 2 cards, got %d", label, len(hole))
	}
	if len(community) != 5 {
		return status.Errorf(codes.InvalidArgument, "%s: community_cards must have 5 cards, got %d", label, len(community))
	}
	return nil
}
