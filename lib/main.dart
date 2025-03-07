import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Card Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MemoryGame(),
    );
  }
}

class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});

  @override
  State<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<MemoryGame> {
  // List of 8 emojis (will be duplicated to create 16 cards)
  final List<String> emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];

  // List to store all 16 cards (8 pairs)
  late List<CardModel> cards;
  bool isGameStarted = false;
  bool isMemorizing = true;
  double progress = 1.0;
  Timer? timer;
  int remainingSeconds = 30;
  int memorizationSeconds = 10;
  int matchedPairs = 0;
  int wrongAttempts = 0; // Add counter for wrong attempts
  CardModel? firstCard;
  bool canTap = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    // Create pairs of cards
    cards = [];
    // First create all cards with their emojis
    for (var emoji in emojis) {
      cards.add(CardModel(emoji: emoji));
      cards.add(CardModel(emoji: emoji));
    }
    // Then shuffle the cards
    cards.shuffle(Random());

    // Reset all game state
    setState(() {
      matchedPairs = 0;
      wrongAttempts = 0; // Reset wrong attempts counter
      isGameStarted = false;
      isMemorizing = true;
      progress = 1.0;
      remainingSeconds = 30;
      memorizationSeconds = 10;
      firstCard = null;
      canTap = true;

      // Start with all cards face down
      for (var card in cards) {
        card.isFlipped = false;
        card.isMatched = false;
      }
    });

    // Cancel any existing timer
    timer?.cancel();
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      // Show all cards face up for memorization
      for (var card in cards) {
        card.isFlipped = true;
      }
    });

    // Start memorization countdown
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (memorizationSeconds > 0) {
            memorizationSeconds--;
            progress = memorizationSeconds / 10;
          } else {
            timer.cancel();
            isMemorizing = false;
            // Hide all cards face down
            for (var card in cards) {
              card.isFlipped = false;
            }
            _startCountdown();
          }
        });
      }
    });
  }

  void _startCountdown() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (remainingSeconds > 0) {
            remainingSeconds--;
            progress = remainingSeconds / 30;
          } else {
            timer.cancel();
            _showGameOverDialog();
          }
        });
      }
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over!'),
        content:
            Text('You matched $matchedPairs pairs!\nToo many wrong attempts!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _onCardTap(CardModel card) {
    if (!canTap || card.isMatched || card.isFlipped) return;

    setState(() {
      if (firstCard == null) {
        firstCard = card;
        card.isFlipped = true;
      } else {
        card.isFlipped = true;
        canTap = false;

        if (firstCard!.emoji == card.emoji) {
          firstCard!.isMatched = true;
          card.isMatched = true;
          matchedPairs++;
          firstCard = null;
          canTap = true;

          // Check if all pairs are matched
          if (matchedPairs == emojis.length) {
            _showVictoryDialog();
          }
        } else {
          wrongAttempts++; // Increment wrong attempts counter
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              setState(() {
                firstCard!.isFlipped = false;
                card.isFlipped = false;
                firstCard = null;
                canTap = true;

                // Check if too many wrong attempts
                if (wrongAttempts >= 5) {
                  _showGameOverDialog();
                }
              });
            }
          });
        }
      }
    });
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations! 🎉'),
        content: const Text('You won! All pairs matched!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Card Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isGameStarted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: startGame,
                    child: const Text('Start Game'),
                  ),
                ),
              if (isGameStarted && isMemorizing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      Text(
                        'Memorize the cards! ($memorizationSeconds seconds)',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              // Row 1
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCell(0),
                  _buildCell(1),
                  _buildCell(2),
                  _buildCell(3),
                ],
              ),
              const SizedBox(height: 10),
              // Row 2
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCell(4),
                  _buildCell(5),
                  _buildCell(6),
                  _buildCell(7),
                ],
              ),
              const SizedBox(height: 10),
              // Row 3
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCell(8),
                  _buildCell(9),
                  _buildCell(10),
                  _buildCell(11),
                ],
              ),
              const SizedBox(height: 10),
              // Row 4
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCell(12),
                  _buildCell(13),
                  _buildCell(14),
                  _buildCell(15),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    return GestureDetector(
      onTap: () => _onCardTap(cards[index]),
      child: Container(
        width: 50,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: cards[index].isFlipped ? Colors.blue[100] : Colors.blue[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: cards[index].isFlipped
              ? Text(
                  cards[index].emoji,
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
      ),
    );
  }
}

class CardModel {
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardModel({
    required this.emoji,
    this.isFlipped = false,
    this.isMatched = false,
  });
}
