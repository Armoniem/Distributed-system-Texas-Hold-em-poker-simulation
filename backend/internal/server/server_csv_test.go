package server

import (
	"context"
	"testing"

	pb "github.com/armoniem/pokereval/backend/gen/pokereval"
)

// cmpTest encodes one row from the CSV hand comparison test cases.
type cmpTest struct {
	name       string
	hole1      []string
	community1 []string
	hole2      []string
	community2 []string
	want       string // "player1", "player2", or "draw"
}

// In the CSV both players share the same community cards.
// CompareHands is called with the same community for both players.
var csvTests = []cmpTest{
	// ── High Card ────────────────────────────────────────────────────────────
	{
		name:       "HighCard_AcKingVsAceQueen",
		hole1:      []string{"SK", "CA"},
		community1: []string{"D6", "S9", "H4", "S3", "C2"},
		hole2:      []string{"HA", "SQ"},
		community2: []string{"D6", "S9", "H4", "S3", "C2"},
		want:       "player1", // K kicker > Q kicker
	},
	{
		name:       "HighCard_AceKingVsAceKing_Draw",
		hole1:      []string{"SK", "CA"},
		community1: []string{"D6", "S9", "H4", "S3", "C2"},
		hole2:      []string{"HA", "CK"},
		community2: []string{"D6", "S9", "H4", "S3", "C2"},
		want:       "draw",
	},
	{
		name:       "HighCard_QueenVsJack",
		hole1:      []string{"C7", "DQ"},
		community1: []string{"D6", "S9", "H4", "H3", "H2"},
		hole2:      []string{"C8", "DJ"},
		community2: []string{"D6", "S9", "H4", "H3", "H2"},
		want:       "player1", // Q > J
	},

	// ── One Pair ─────────────────────────────────────────────────────────────
	{
		name:       "OnePair_KingPairVsEightPair",
		hole1:      []string{"DK", "C5"},
		community1: []string{"SK", "HT", "C8", "C7", "D2"},
		hole2:      []string{"H8", "D5"},
		community2: []string{"SK", "HT", "C8", "C7", "D2"},
		want:       "player1", // pair K > pair 8
	},
	{
		name:       "OnePair_KingPairVsKingPair_Draw",
		hole1:      []string{"DK", "C4"},
		community1: []string{"SK", "HT", "C8", "C7", "D2"},
		hole2:      []string{"HK", "D5"},
		community2: []string{"SK", "HT", "C8", "C7", "D2"},
		want:       "draw",
	},
	{
		name:       "OnePair_SevenKickerVsSixKicker",
		hole1:      []string{"D5", "C6"},
		community1: []string{"HA", "DA", "ST", "C9", "D4"},
		hole2:      []string{"H7", "C2"},
		community2: []string{"HA", "DA", "ST", "C9", "D4"},
		want:       "player2", // pair A with 7 kicker vs pair A with 6 kicker; 7>6
	},

	// ── Two Pair ─────────────────────────────────────────────────────────────
	{
		name:       "TwoPair_AceHighVsQueenHigh",
		hole1:      []string{"HA", "C3"},
		community1: []string{"SA", "DQ", "CK", "D6", "H6"},
		hole2:      []string{"CQ", "H4"},
		community2: []string{"SA", "DQ", "CK", "D6", "H6"},
		want:       "player1", // A-A-6-6 > Q-Q-6-6
	},
	{
		name:       "TwoPair_Queens_Draw",
		hole1:      []string{"HQ", "C3"},
		community1: []string{"SA", "DQ", "CK", "D6", "H6"},
		hole2:      []string{"SQ", "H4"},
		community2: []string{"SA", "DQ", "CK", "D6", "H6"},
		want:       "draw",
	},
	{
		name:       "TwoPair_AcePairsVsQueenPairs",
		hole1:      []string{"HQ", "C6"},
		community1: []string{"SA", "DQ", "CK", "D6", "H5"},
		hole2:      []string{"CA", "HK"},
		community2: []string{"SA", "DQ", "CK", "D6", "H5"},
		want:       "player2", // A-A-K-K > Q-Q-6-6
	},

	// ── Three of a Kind ──────────────────────────────────────────────────────
	{
		name:       "ThreeOfAKind_TripsThrees_Draw",
		hole1:      []string{"C3", "S2"},
		community1: []string{"SA", "D3", "H3", "C8", "SJ"},
		hole2:      []string{"S3", "H2"},
		community2: []string{"SA", "D3", "H3", "C8", "SJ"},
		want:       "draw", // trips 3 with same kickers (A, J)
	},
	{
		name:       "ThreeOfAKind_KingKickerVsTenKicker",
		hole1:      []string{"S2", "S5"},
		community1: []string{"HA", "SA", "DA", "H3", "HT"},
		hole2:      []string{"H2", "SK"},
		community2: []string{"HA", "SA", "DA", "H3", "HT"},
		want:       "player2", // trips A with K kicker > trips A with T kicker
	},

	// ── Straight ─────────────────────────────────────────────────────────────
	{
		name:       "Straight_SevenHighVsSixHigh",
		hole1:      []string{"D7", "HA"},
		community1: []string{"H3", "S4", "C5", "S6", "HT"},
		hole2:      []string{"H2", "SA"},
		community2: []string{"H3", "S4", "C5", "S6", "HT"},
		want:       "player1", // 7-high straight > 6-high (A-2-3-4-5)
	},
	{
		name:       "Straight_SevenVsSeven_Draw",
		hole1:      []string{"D7", "HA"},
		community1: []string{"H3", "S4", "C5", "S6", "HT"},
		hole2:      []string{"H7", "SA"},
		community2: []string{"H3", "S4", "C5", "S6", "HT"},
		want:       "draw",
	},
	{
		name:       "Straight_AceLowVsSixHigh",
		hole1:      []string{"HA", "S3"},
		community1: []string{"H2", "H3", "S4", "C5", "HT"},
		hole2:      []string{"H6", "SA"},
		community2: []string{"H2", "H3", "S4", "C5", "HT"},
		want:       "player2", // 6-high straight > A-2-3-4-5 (5-high)
	},

	// ── Flush ─────────────────────────────────────────────────────────────────
	{
		name:       "Flush_AceKingVsAceQueen",
		hole1:      []string{"DK", "DA"},
		community1: []string{"D3", "D6", "DT", "C5", "HQ"},
		hole2:      []string{"D2", "DQ"},
		community2: []string{"D3", "D6", "DT", "C5", "HQ"},
		want:       "player1", // A-flush beats Q-flush
	},
	{
		name:       "Flush_SameBoard_Draw",
		hole1:      []string{"C3", "HA"},
		community1: []string{"D3", "D6", "DT", "DJ", "DK"},
		hole2:      []string{"S9", "HJ"},
		community2: []string{"D3", "D6", "DT", "DJ", "DK"},
		want:       "draw", // best 5 is the community flush for both
	},
	{
		name:       "Flush_AceHighVsFiveHigh",
		hole1:      []string{"D2", "D5"},
		community1: []string{"D3", "D6", "DT", "C5", "HQ"},
		hole2:      []string{"DJ", "DA"},
		community2: []string{"D3", "D6", "DT", "C5", "HQ"},
		want:       "player2", // A-K-J-T-3 flush > 6-5-3-2-? flush
	},

	// ── Full House ───────────────────────────────────────────────────────────
	{
		name:       "FullHouse_TripQueensVsTripTens",
		hole1:      []string{"DQ", "C2"},
		community1: []string{"HQ", "SQ", "HT", "DT", "C3"},
		hole2:      []string{"CT", "C4"},
		community2: []string{"HQ", "SQ", "HT", "DT", "C3"},
		want:       "player1", // QQQ-TT > TTT-QQ
	},
	{
		name:       "FullHouse_SameFullHouse_Draw",
		hole1:      []string{"HA", "DQ"},
		community1: []string{"SA", "HQ", "SQ", "HT", "D8"},
		hole2:      []string{"DA", "CQ"},
		community2: []string{"SA", "HQ", "SQ", "HT", "D8"},
		want:       "draw",
	},
	{
		name:       "FullHouse_TripTensVsTripQueens",
		hole1:      []string{"ST", "C2"},
		community1: []string{"HQ", "SQ", "HT", "DT", "C3"},
		hole2:      []string{"CQ", "C4"},
		community2: []string{"HQ", "SQ", "HT", "DT", "C3"},
		want:       "player2", // QQQ-TT > TTT-QQ
	},

	// ── Four of a Kind ───────────────────────────────────────────────────────
	{
		name:       "FourOfAKind_AceKickerVsKingKicker",
		hole1:      []string{"HA", "S7"},
		community1: []string{"HT", "ST", "CT", "DT", "HK"},
		hole2:      []string{"DJ", "C5"},
		community2: []string{"HT", "ST", "CT", "DT", "HK"},
		want:       "player1", // quad T with A kicker > quad T with K kicker
	},
	{
		name:       "FourOfAKind_SameQuad_Draw",
		hole1:      []string{"CT", "HT"},
		community1: []string{"S5", "D5", "C5", "H5", "HA"},
		hole2:      []string{"C4", "SQ"},
		community2: []string{"S5", "D5", "C5", "H5", "HA"},
		want:       "draw", // quad 5 with A kicker for both
	},
	{
		name:       "FourOfAKind_KingVsEightKicker",
		hole1:      []string{"C2", "C3"},
		community1: []string{"HT", "ST", "CT", "DT", "S8"},
		hole2:      []string{"C5", "HK"},
		community2: []string{"HT", "ST", "CT", "DT", "S8"},
		want:       "player2", // quad T with K kicker > quad T with 8 kicker
	},

	// ── Straight Flush ───────────────────────────────────────────────────────
	{
		name:       "StraightFlush_SevenHighVsSixHigh",
		hole1:      []string{"H7", "HA"},
		community1: []string{"H3", "H4", "H5", "H6", "HT"},
		hole2:      []string{"H2", "SA"},
		community2: []string{"H3", "H4", "H5", "H6", "HT"},
		want:       "player1", // str.fl. 7-high > str.fl. 6-high (A-2-3-4-5)
	},
	{
		name:       "StraightFlush_SameBoard_Draw",
		hole1:      []string{"HA", "ST"},
		community1: []string{"H3", "H4", "H5", "H6", "H7"},
		hole2:      []string{"CQ", "D6"},
		community2: []string{"H3", "H4", "H5", "H6", "H7"},
		want:       "draw",
	},
	{
		name:       "StraightFlush_JackHighVsTenHigh",
		hole1:      []string{"S6", "C2"},
		community1: []string{"S7", "S8", "S9", "ST", "DK"},
		hole2:      []string{"SJ", "D5"},
		community2: []string{"S7", "S8", "S9", "ST", "DK"},
		want:       "player2", // J-high str.fl. > T-high str.fl.
	},

	// ── Royal Flush ──────────────────────────────────────────────────────────
	{
		name:       "RoyalFlush_BothFromCommunity_Draw",
		hole1:      []string{"H2", "S3"}, // irrelevant – best hand is in community
		community1: []string{"DT", "DJ", "DQ", "DK", "DA"},
		hole2:      []string{"C4", "S5"},
		community2: []string{"DT", "DJ", "DQ", "DK", "DA"},
		want:       "draw",
	},
}

func TestCSV_CompareHands(t *testing.T) {
	for _, tc := range csvTests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			resp, err := srv.CompareHands(context.Background(), &pb.CompareHandsRequest{
				HoleCards1:      tc.hole1,
				CommunityCards1: tc.community1,
				HoleCards2:      tc.hole2,
				CommunityCards2: tc.community2,
			})
			if err != nil {
				t.Fatalf("CompareHands error: %v", err)
			}
			if resp.Winner != tc.want {
				t.Errorf("got winner=%q, want %q | hand1=%s (%d) vs hand2=%s (%d)",
					resp.Winner, tc.want,
					resp.Hand1.Category, resp.Hand1.Strength,
					resp.Hand2.Category, resp.Hand2.Strength,
				)
			}
		})
	}
}
