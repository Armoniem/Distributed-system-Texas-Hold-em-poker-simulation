// Package poker contains core Texas Hold'em domain logic.
package poker

import "fmt"

// Suit constants.
const (
	SuitHearts   = 0
	SuitSpades   = 1
	SuitDiamonds = 2
	SuitClubs    = 3
)

// Card represents a single playing card.
type Card struct {
	Rank int // 2–14 (Ace = 14)
	Suit int // 0=H, 1=S, 2=D, 3=C
}

var suitNames = [4]string{"H", "S", "D", "C"}
var rankNames = map[int]string{
	2: "2", 3: "3", 4: "4", 5: "5", 6: "6",
	7: "7", 8: "8", 9: "9", 10: "T",
	11: "J", 12: "Q", 13: "K", 14: "A",
}

// ParseCard parses a 2-character card string (suit+rank, e.g. "HA", "S7", "CT").
func ParseCard(s string) (Card, error) {
	if len(s) != 2 {
		return Card{}, fmt.Errorf("invalid card %q: must be 2 characters (suit+rank)", s)
	}

	var suit int
	switch s[0] {
	case 'H', 'h':
		suit = SuitHearts
	case 'S', 's':
		suit = SuitSpades
	case 'D', 'd':
		suit = SuitDiamonds
	case 'C', 'c':
		suit = SuitClubs
	default:
		return Card{}, fmt.Errorf("invalid suit %c in card %q (expected H/S/D/C)", s[0], s)
	}

	var rank int
	switch s[1] {
	case '2':
		rank = 2
	case '3':
		rank = 3
	case '4':
		rank = 4
	case '5':
		rank = 5
	case '6':
		rank = 6
	case '7':
		rank = 7
	case '8':
		rank = 8
	case '9':
		rank = 9
	case 'T', 't':
		rank = 10
	case 'J', 'j':
		rank = 11
	case 'Q', 'q':
		rank = 12
	case 'K', 'k':
		rank = 13
	case 'A', 'a':
		rank = 14
	default:
		return Card{}, fmt.Errorf("invalid rank %c in card %q (expected 2-9,T,J,Q,K,A)", s[1], s)
	}

	return Card{Rank: rank, Suit: suit}, nil
}

// ParseCards parses a slice of card strings.
func ParseCards(ss []string) ([]Card, error) {
	cards := make([]Card, 0, len(ss))
	seen := make(map[string]bool)
	for _, s := range ss {
		if seen[s] {
			return nil, fmt.Errorf("duplicate card: %q", s)
		}
		seen[s] = true
		c, err := ParseCard(s)
		if err != nil {
			return nil, err
		}
		cards = append(cards, c)
	}
	return cards, nil
}

// String returns the canonical 2-character representation of the card.
func (c Card) String() string {
	return suitNames[c.Suit] + rankNames[c.Rank]
}

// FullDeck returns all 52 cards.
func FullDeck() []Card {
	deck := make([]Card, 0, 52)
	for suit := 0; suit < 4; suit++ {
		for rank := 2; rank <= 14; rank++ {
			deck = append(deck, Card{Rank: rank, Suit: suit})
		}
	}
	return deck
}

// RemainingDeck returns the 52-card deck minus the provided known cards.
func RemainingDeck(known []Card) []Card {
	excluded := make(map[Card]bool, len(known))
	for _, c := range known {
		excluded[c] = true
	}
	deck := make([]Card, 0, 52-len(known))
	for suit := 0; suit < 4; suit++ {
		for rank := 2; rank <= 14; rank++ {
			c := Card{Rank: rank, Suit: suit}
			if !excluded[c] {
				deck = append(deck, c)
			}
		}
	}
	return deck
}
