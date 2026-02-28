package poker

import (
	"math/rand"
	"sync"
	"sync/atomic"
)

// SimResult holds the aggregate outcome of a Monte Carlo simulation run.
type SimResult struct {
	Wins  int64
	Draws int64
	Total int64
}

const numWorkers = 8

// MonteCarloSimulate estimates win/draw probability for the given hole cards
// against (numPlayers-1) random opponents.
//
//   - holecards: exactly 2 cards
//   - community: 0, 3, 4, or 5 cards already known
//   - numPlayers: total players including hero (2–9)
//   - numSims: total simulations to run
func MonteCarloSimulate(holecards, community []Card, numPlayers, numSims int) SimResult {
	if numSims < 1 {
		numSims = 1000
	}
	if numPlayers < 2 {
		numPlayers = 2
	}

	// Build the base deck (all unknown cards).
	known := append(holecards, community...) //nolint:gocritic
	baseDeck := RemainingDeck(known)

	// How many more community cards need to be simulated.
	communityNeeded := 5 - len(community)
	// Cards needed from deck per simulation: communityNeeded + 2*(numPlayers-1)
	cardsPerSim := communityNeeded + 2*(numPlayers-1)
	if cardsPerSim > len(baseDeck) {
		// Impossible situation – return 50% win
		return SimResult{Wins: int64(numSims / 2), Total: int64(numSims)}
	}

	simsPerWorker := numSims / numWorkers
	remainder := numSims % numWorkers

	var wins, draws int64
	var wg sync.WaitGroup

	for w := 0; w < numWorkers; w++ {
		count := simsPerWorker
		if w == 0 {
			count += remainder // the first worker handles the remainder
		}
		wg.Add(1)
		go func(simCount int) {
			defer wg.Done()
			rng := rand.New(rand.NewSource(rand.Int63()))
			deck := make([]Card, len(baseDeck))

			for s := 0; s < simCount; s++ {
				copy(deck, baseDeck)
				// Fisher-Yates shuffle for the first cardsPerSim cards.
				for i := 0; i < cardsPerSim; i++ {
					j := i + rng.Intn(len(deck)-i)
					deck[i], deck[j] = deck[j], deck[i]
				}

				// Simulated board: existing community + newly drawn cards.
				board := make([]Card, 0, 5)
				board = append(board, community...)
				board = append(board, deck[:communityNeeded]...)

				// Hero hand = hole cards + board.
				heroCards := make([]Card, 0, 7)
				heroCards = append(heroCards, holecards...)
				heroCards = append(heroCards, board...)
				heroResult := EvaluateBestHand(heroCards)

				// Opponent hands share the same board.
				remaining := deck[communityNeeded:]
				heroWins := true
				heroDraw := false

				for p := 0; p < numPlayers-1; p++ {
					opHole := remaining[p*2 : p*2+2]
					opCards := make([]Card, 0, 7)
					opCards = append(opCards, opHole...)
					opCards = append(opCards, board...)
					opResult := EvaluateBestHand(opCards)

					if opResult.Strength > heroResult.Strength {
						heroWins = false
						heroDraw = false
						break // already lost, no need to check more opponents
					}
					if opResult.Strength == heroResult.Strength {
						heroDraw = true
						heroWins = false
					}
				}

				if heroWins {
					atomic.AddInt64(&wins, 1)
				} else if heroDraw {
					atomic.AddInt64(&draws, 1)
				}
			}
		}(count)
	}
	wg.Wait()

	return SimResult{
		Wins:  wins,
		Draws: draws,
		Total: int64(numSims),
	}
}
