package poker

import "sort"

// HandRank is the category of a poker hand, ordered lowest to highest.
type HandRank int

const (
	HighCard HandRank = iota
	OnePair
	TwoPair
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
	RoyalFlush
)

// String returns the human-readable name of a hand rank.
func (h HandRank) String() string {
	switch h {
	case RoyalFlush:
		return "Royal Flush"
	case StraightFlush:
		return "Straight Flush"
	case FourOfAKind:
		return "Four of a Kind"
	case FullHouse:
		return "Full House"
	case Flush:
		return "Flush"
	case Straight:
		return "Straight"
	case ThreeOfAKind:
		return "Three of a Kind"
	case TwoPair:
		return "Two Pair"
	case OnePair:
		return "One Pair"
	default:
		return "High Card"
	}
}

// HandResult holds the evaluation result for a poker hand.
type HandResult struct {
	Cards    []Card
	Rank     HandRank
	Strength int64  // larger = stronger; used for comparison
	Category string // human-readable, e.g. "Full House"
}

// EvaluateBestHand finds the best 5-card poker hand from 5–7 cards.
func EvaluateBestHand(cards []Card) HandResult {
	if len(cards) < 5 {
		return HandResult{Category: "Invalid – need ≥5 cards"}
	}
	combos := combinations5(cards)
	var best HandResult
	for _, combo := range combos {
		r := evaluate5(combo)
		if r.Strength > best.Strength {
			best = r
		}
	}
	return best
}

// combinations5 returns all C(n,5) subsets of cards.
func combinations5(cards []Card) [][]Card {
	n := len(cards)
	var result [][]Card
	var helper func(start int, combo []Card)
	helper = func(start int, combo []Card) {
		if len(combo) == 5 {
			c := make([]Card, 5)
			copy(c, combo)
			result = append(result, c)
			return
		}
		for i := start; i < n; i++ {
			helper(i+1, append(combo, cards[i]))
		}
	}
	helper(0, nil)
	return result
}

// evaluate5 evaluates exactly 5 cards.
func evaluate5(cards []Card) HandResult {
	// Sort descending by rank for easier analysis.
	sorted := make([]Card, 5)
	copy(sorted, cards)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i].Rank > sorted[j].Rank })

	ranks := [5]int{sorted[0].Rank, sorted[1].Rank, sorted[2].Rank, sorted[3].Rank, sorted[4].Rank}

	// Check flush.
	isFlush := sorted[0].Suit == sorted[1].Suit &&
		sorted[1].Suit == sorted[2].Suit &&
		sorted[2].Suit == sorted[3].Suit &&
		sorted[3].Suit == sorted[4].Suit

	// Check straight.
	isStraight, isLowAce := checkStraight(ranks)

	// Count rank occurrences.
	rankCount := make(map[int]int, 5)
	for _, r := range ranks {
		rankCount[r]++
	}

	// Build sorted pairs (count desc, then rank desc) for quick classification.
	type pair struct{ rank, count int }
	pairs := make([]pair, 0, len(rankCount))
	for r, c := range rankCount {
		pairs = append(pairs, pair{r, c})
	}
	sort.Slice(pairs, func(i, j int) bool {
		if pairs[i].count != pairs[j].count {
			return pairs[i].count > pairs[j].count
		}
		return pairs[i].rank > pairs[j].rank
	})

	var handRank HandRank
	var tiebreakers [5]int

	switch {
	case isFlush && isStraight && !isLowAce && ranks[0] == 14: // A-K-Q-J-T same suit
		handRank = RoyalFlush
		tiebreakers = ranks

	case isFlush && isStraight:
		handRank = StraightFlush
		if isLowAce {
			tiebreakers = [5]int{5, 4, 3, 2, 1}
		} else {
			tiebreakers = ranks
		}

	case pairs[0].count == 4:
		handRank = FourOfAKind
		tiebreakers = [5]int{pairs[0].rank, pairs[1].rank, 0, 0, 0}

	case pairs[0].count == 3 && pairs[1].count == 2:
		handRank = FullHouse
		tiebreakers = [5]int{pairs[0].rank, pairs[1].rank, 0, 0, 0}

	case isFlush:
		handRank = Flush
		tiebreakers = ranks

	case isStraight:
		handRank = Straight
		if isLowAce {
			tiebreakers = [5]int{5, 4, 3, 2, 1}
		} else {
			tiebreakers = ranks
		}

	case pairs[0].count == 3:
		handRank = ThreeOfAKind
		// trips first, then kickers desc
		tiebreakers = [5]int{pairs[0].rank, pairs[1].rank, pairs[2].rank, 0, 0}

	case pairs[0].count == 2 && pairs[1].count == 2:
		handRank = TwoPair
		tiebreakers = [5]int{pairs[0].rank, pairs[1].rank, pairs[2].rank, 0, 0}

	case pairs[0].count == 2:
		handRank = OnePair
		tiebreakers = [5]int{pairs[0].rank, pairs[1].rank, pairs[2].rank, pairs[3].rank, 0}

	default:
		handRank = HighCard
		tiebreakers = ranks
	}

	strength := computeStrength(handRank, tiebreakers)
	return HandResult{
		Cards:    sorted,
		Rank:     handRank,
		Strength: strength,
		Category: handRank.String(),
	}
}

// checkStraight returns whether the sorted (desc) 5 ranks form a straight,
// and whether it is an ace-low (A-2-3-4-5) straight.
func checkStraight(ranks [5]int) (isStraight, isLowAce bool) {
	// Normal straight: each rank exactly 1 less than the previous.
	normal := true
	for i := 1; i < 5; i++ {
		if ranks[i-1]-ranks[i] != 1 {
			normal = false
			break
		}
	}
	if normal {
		return true, false
	}
	// Ace-low: A-5-4-3-2 stored as [14,5,4,3,2]
	if ranks[0] == 14 && ranks[1] == 5 && ranks[2] == 4 && ranks[3] == 3 && ranks[4] == 2 {
		return true, true
	}
	return false, false
}

// computeStrength encodes hand rank and tiebreakers into a single int64.
// Layout: [4 bits hand rank][5 × 4 bits tiebreaker ranks]
func computeStrength(rank HandRank, tiebreakers [5]int) int64 {
	var s int64
	s = int64(rank) << 20
	for i, t := range tiebreakers {
		s |= int64(t&0xf) << (uint(4-i) * 4)
	}
	return s
}

// CardsToStrings converts a slice of Cards to their string representations.
func CardsToStrings(cards []Card) []string {
	out := make([]string, len(cards))
	for i, c := range cards {
		out[i] = c.String()
	}
	return out
}
