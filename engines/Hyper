using System;
using System.Collections.Generic;
using System.Linq;
using ChessDotNet;
using ChessDotNet.Pieces;
using File = ChessDotNet.File;









public class Hyper
{
    // Keeping track of which quiet move move is most likely to cause a beta cutoff.
    // The higher the score is, the more likely a beta cutoff is, so in move ordering we will put these moves first.
    long[] quietHistory = new long[4096];

    // Transposition table
    // Format: Position key, move, depth, score, flag
    (ulong, Move, int, int, byte)[] TT = new (ulong, Move, int, int, byte)[2097152];

    // Due to the rules of the challenge and how token counting works, evaluation constants are packed into C# decimals,
    // as they allow the most efficient (12 usable bits per token).
    // The ordering is as follows: Midgame term 1, endgame term 1, midgame, term 2, endgame term 2...
    static sbyte[] extracted = new[] { 4835740172228143389605888m, 1862983114964290202813595648m, 6529489037797228073584297991m, 6818450810788061916507740187m, 7154536855449028663353021722m, 14899014974757699833696556826m, 25468819436707891759039590695m, 29180306561342183501734565961m, 944189991765834239743752701m, 4194697739m, 4340114601700738076711583744m, 3410436627687897068963695623m, 11182743911298765866015857947m, 10873240011723255639678263585m, 17684436730682332602697851426m, 17374951722591802467805509926m, 31068658689795177567161113954m, 1534136309681498319279645285m, 18014679997410182140m, 1208741569195510172352512m, 13789093343132567021105512448m, 6502873946609222871099113472m, 1250m }.SelectMany(x => decimal.GetBits(x).Take(3).SelectMany(y => (sbyte[])(Array)BitConverter.GetBytes(y))).ToArray();

    // After extracting the raw mindgame/endgame terms, we repack it into integers of midgame/endgame pairs.
    // The scheme in bytes (assuming little endian) is: 00 EG 00 MG
    // The idea of this is that we can do operations on both midgame and endgame values simultaneously, preventing the need
    // for evaluation for separate mid-game / end-game terms.
    int[] evalValues = Enumerable.Range(0, 138).Select(i => extracted[i * 2] | extracted[i * 2 + 1] << 16).ToArray();

    private ChessGame _game;
    private Dictionary<ulong, int> _positionHistory;
    private ulong _zobristKey;

    public Hyper()
    {
        _game = new ChessGame();
        _positionHistory = new Dictionary<ulong, int>();
        _zobristKey = Zobrist.CalculateZobristKey(_game);
    }

    // Custom Zobrist Hashing (simplified for demonstration)
    public static class Zobrist
    {
        private static readonly ulong[,] PieceKeys = new ulong[12, 64]; // 6 piece types * 2 colors, 64 squares
        private static readonly ulong[] CastlingKeys = new ulong[16]; // 16 possible castling states
        private static readonly ulong[] EnPassantKeys = new ulong[9]; // 8 files + no en passant
        private static readonly ulong BlackToMoveKey;

        static Zobrist()
        {
            Random rand = new Random(12345); // Fixed seed for reproducibility
            for (int i = 0; i < 12; i++)
            {
                for (int j = 0; j < 64; j++)
                {
                    PieceKeys[i, j] = (ulong)rand.Next() << 32 | (ulong)rand.Next();
                }
            }
            for (int i = 0; i < 16; i++)
            {
                CastlingKeys[i] = (ulong)rand.Next() << 32 | (ulong)rand.Next();
            }
            for (int i = 0; i < 9; i++)
            {
                EnPassantKeys[i] = (ulong)rand.Next() << 32 | (ulong)rand.Next();
            }
            BlackToMoveKey = (ulong)rand.Next() << 32 | (ulong)rand.Next();
        }

        public static ulong CalculateZobristKey(ChessGame game)
        {
            ulong hash = 0;
            for (int rank = 0; rank < 8; rank++)
            {
                for (int file = 0; file < 8; file++)
                {
                    Piece piece = game.GetPieceAt((ChessDotNet.File)file, 8 - rank);
                    if (piece != null)
                    {
                        int pieceType = GetPieceTypeIndex(piece);
                        int square = rank * 8 + file;
                        hash ^= PieceKeys[pieceType, square];
                    }
                }
            }

            // Castling rights (simplified, needs proper mapping to 16 states)
            // For now, a basic representation
            if (game.CanWhiteKingSideCastle) hash ^= CastlingKeys[0];
            if (game.CanWhiteQueenSideCastle) hash ^= CastlingKeys[1];
            if (game.CanBlackKingSideCastle) hash ^= CastlingKeys[2];
            if (game.CanBlackQueenSideCastle) hash ^= CastlingKeys[3];

            // En passant target square (simplified)
            // Needs to map to 9 states (8 files + none)
            // For now, a basic representation
            if (game.EnPassantrawnSquare != null)
            {
                hash ^= EnPassantKeys[(int)game.EnPassantrawnSquare.Value.File + 1];
            }

            if (game.WhoseTurn == Player.Black)
            {
                hash ^= BlackToMoveKey;
            }

            return hash;
        }

        private static int GetPieceTypeIndex(Piece piece)
        {
            int index = 0;
            if (piece.Owner == Player.Black) index += 6;

            switch (piece)
            {
                case ChessDotNet.Pieces.Pawn _ : return index + 0;
                case ChessDotNet.Pieces.Knight _ : return index + 1;
                case ChessDotNet.Pieces.Bishop _ : return index + 2;
                case ChessDotNet.Pieces.Rook _ : return index + 3;
                case ChessDotNet.Pieces.Queen _ : return index + 4;
                case ChessDotNet.Pieces.King _ : return index + 5;
                default: return 0; // Should not happen
            }
        }

        private static Type GetPieceTypeFromIndex(int pieceIndex)
        {
            switch (pieceIndex)
            {
                case 1: return typeof(ChessDotNet.Pieces.Pawn);
                case 2: return typeof(ChessDotNet.Pieces.Knight);
                case 3: return typeof(ChessDotNet.Pieces.Bishop);
                case 4: return typeof(ChessDotNet.Pieces.Rook);
                case 5: return typeof(ChessDotNet.Pieces.Queen);
                case 6: return typeof(ChessDotNet.Pieces.King);
                default: return null; // Should not happen
            }
        }
    }

    // Custom BitboardHelper (simplified for demonstration)
    public static class BitboardHelper
    {
        public static ulong GetPieceBitboard(Type pieceType, bool isWhite, ChessGame game)
        {
            ulong bitboard = 0;
            Player player = isWhite ? Player.White : Player.Black;

            for (int rank = 0; rank < 8; rank++)
            {
                for (int file = 0; file < 8; file++)
                {
                    Piece piece = game.GetPieceAt((ChessDotNet.File)file, 8 - rank);
                    if (piece != null && piece is ChessDotNet.Pieces.King && piece.Owner == player)
                    {
                        bitboard |= (1UL << (rank * 8 + file));
                    }
                }
            }
            return bitboard;
        }

        public static int ClearAndGetIndexOfLSB(ref ulong bitboard)
        {
            if (bitboard == 0) return -1;
            int index = 0;
            ulong temp = bitboard;
            while ((temp & 1) == 0)
            {
                temp >>= 1;
                index++;
            }
            bitboard &= (bitboard - 1); // Clear the LSB
            return index;
        }

        public static int GetNumberOfSetBits(ulong bitboard)
        {
            int count = 0;
            while (bitboard != 0)
            {
                bitboard &= (bitboard - 1);
                count++;
            }
            return count;
        }

        // Simplified GetPieceAttacks - needs to be more robust
        public static ulong GetPieceAttacks(Type pieceType, Position square, ChessGame game, bool isWhite)
        {
            // This is a highly simplified version. A real implementation would involve
            // iterating through possible moves for the piece from that square.
            // For now, returning 0 to avoid compilation errors.
            return 0;
        }

        // Simplified GetKingAttacks - needs to be more robust
        public static ulong GetKingAttacks(Position kingSquare)
        {
            // This is a highly simplified version. A real implementation would involve
            // precomputed tables or calculating king moves.
            // For now, returning 0 to avoid compilation errors.
            return 0;
        }
    }

    // Custom Board Extensions
    public class BoardExtensions
    {
        private ChessGame _game;
        private Stack<Move> _moveHistory;
        private Stack<ulong> _zobristHistory;
        private Stack<Dictionary<ulong, int>> _positionHistoryStack;

        public BoardExtensions(ChessGame game, Dictionary<ulong, int> positionHistory, ulong initialZobrist)
        {
            _game = game;
            _moveHistory = new Stack<Move>();
            _zobristHistory = new Stack<ulong>();
            _positionHistoryStack = new Stack<Dictionary<ulong, int>>();
            _positionHistoryStack.Push(new Dictionary<ulong, int>(positionHistory)); // Copy initial history
            _zobristHistory.Push(initialZobrist);
        }

        public void MakeMove(Move move)
        {
            _moveHistory.Push(move);
            _positionHistoryStack.Push(new Dictionary<ulong, int>(_positionHistoryStack.Peek())); // Copy history
            _game.MakeMove(move, true);
            _zobristHistory.Push(Zobrist.CalculateZobristKey(_game));
            _positionHistoryStack.Peek()[_zobristHistory.Peek()] = _positionHistoryStack.Peek().GetValueOrDefault(_zobristHistory.Peek()) + 1;
        }

        public void UndoMove(Move move)
        {
            _game.UndoLastMove(); // ChessDotNet has UndoLastMove
            _moveHistory.Pop();
            _zobristHistory.Pop();
            _positionHistoryStack.Pop();
        }

        public bool IsRepeatedPosition()
        {
            return _positionHistoryStack.Peek().Any(kv => kv.Value >= 2);
        }

        public bool IsInCheck()
        {
            return _game.IsInCheck(_game.WhoseTurn);
        }

        public List<Move> GetLegalMoves(bool inQsearch)
        {
            // This needs to be adapted based on inQsearch. For now, return all legal moves.
            return _game.GetValidMoves(_game.WhoseTurn).ToList();
        }

        public void ForceSkipTurn()
        {
            // This is a simplified ForceSkipTurn. A proper null move implementation
            // would involve more state changes (e.g., en passant, castling rights).
            _game.WhoseTurn = _game.WhoseTurn == Player.White ? Player.Black : Player.White;
            _zobristHistory.Push(Zobrist.CalculateZobristKey(_game)); // Update Zobrist key for null move
            _positionHistoryStack.Push(new Dictionary<ulong, int>(_positionHistoryStack.Peek())); // Copy history
            _positionHistoryStack.Peek()[_zobristHistory.Peek()] = _positionHistoryStack.Peek().GetValueOrDefault(_zobristHistory.Peek()) + 1;
        }

        public void UndoSkipTurn()
        {
            _game.WhoseTurn = _game.WhoseTurn == Player.White ? Player.Black : Player.White;
            _zobristHistory.Pop();
            _positionHistoryStack.Pop();
        }

        public ulong ZobristKey => _zobristHistory.Peek();

        public Piece GetPieceAt(File file, int rank)
        {
            return _game.GetPieceAt(file, rank);
        }

        public ulong GetPieceBitboard(Type pieceType, bool isWhite)
        {
            return BitboardHelper.GetPieceBitboard(pieceType, isWhite, _game);
        }

        public Position GetKingSquare(bool isWhite)
        {
            Player player = isWhite ? Player.White : Player.Black;
            for (int rank = 0; rank < 8; rank++)
            {
                for (int file = 0; file < 8; file++)
                {
                    Piece piece = _game.GetPieceAt((File)file, 8 - rank);
                    if (piece != null && piece is ChessDotNet.Pieces.King && piece.Owner == player)
                    {
                        return new Position((File)file, 8 - rank);
                    }
                }
            }
            return null; // Should not happen in a valid game
        }

        public ulong WhitePiecesBitboard
        {
            get
            {
                ulong bitboard = 0;
                for (int rank = 0; rank < 8; rank++)
                {
                    for (int file = 0; file < 8; file++)
                    {
                        Piece piece = _game.GetPieceAt((File)file, 8 - rank);
                        if (piece != null && piece.Owner == Player.White)
                        {
                            bitboard |= (1UL << (rank * 8 + file));
                        }
                    }
                }
                return bitboard;
            }
        }

        public ulong BlackPiecesBitboard
        {
            get
            {
                ulong bitboard = 0;
                for (int rank = 0; rank < 8; rank++)
                {
                    for (int file = 0; file < 8; file++)
                    {
                        Piece piece = _game.GetPieceAt((File)file, 8 - rank);
                        if (piece != null && piece.Owner == Player.Black)
                        {
                            bitboard |= (1UL << (rank * 8 + file));
                        }
                    }
                }
                return bitboard;
            }
        }
    }

    public Move Think(BoardExtensions board, int allocatedTime)
    {
        // The move that will eventually be reported as our best move
        Move rootBestMove = default;

        // Intitialise parameters that exist only during one search
        var (killers, i, score, depth) = (new Move[256], 0, 0, 1);

        // Decay quiet history instead of clearing it. 
        for (; i < 4096; quietHistory[i++] /= 8) ;

        // Negamax search is embedded as a local function in order to reduce token count
        int Search(int ply, int depth, int alpha, int beta, bool nullAllowed)
        {
            // Repetition detection
            if (nullAllowed && board.IsRepeatedPosition())
                return 0;

            // Check extension: if we are in check, we should search deeper.
            bool inCheck = board.IsInCheck();
            if (inCheck)
                depth++;

            var (key, inQsearch, bestScore, doPruning, score, phase) = (board.ZobristKey, depth <= 0, -2_000_000, alpha == beta - 1 && !inCheck, 15, 0);

            // Here we do a static evaluation to determine the current static score for the position.
            foreach (bool isWhite in new[] { !(_game.WhoseTurn == Player.White), (_game.WhoseTurn == Player.White) })
            {
                score = -score;

                for (var pieceIndex = 0; ++pieceIndex <= 6;)
                {
                    var bitboard = board.GetPieceBitboard(GetPieceTypeFromIndex(pieceIndex), isWhite);

                    while (bitboard != 0)
                    {
                        var sq = BitboardHelper.ClearAndGetIndexOfLSB(ref bitboard);

                        if ((0x101010101010101UL << sq % 8 & ~(1UL << sq) & board.GetPieceBitboard(typeof(ChessDotNet.Pieces.Pawn), isWhite)) == 0)
                            score += evalValues[126 + pieceIndex];

                        if (pieceIndex > 2)
                        {
                            var mobility = BitboardHelper.GetPieceAttacks(GetPieceTypeFromIndex(pieceIndex), new Position((ChessDotNet.File)(sq % 8), 8 - (sq / 8)), board, isWhite) & ~(isWhite ? board.WhitePiecesBitboard : board.BlackPiecesBitboard);
                            score += evalValues[112 + pieceIndex] * BitboardHelper.GetNumberOfSetBits(mobility)
                                   + evalValues[119 + pieceIndex] * BitboardHelper.GetNumberOfSetBits(mobility & BitboardHelper.GetKingAttacks(board.GetKingSquare(!isWhite)));
                        }

                        if (!isWhite) sq ^= 56;

                        phase += evalValues[pieceIndex];

                        score += evalValues[pieceIndex * 8 + sq / 8]
                               + evalValues[56 + pieceIndex * 8 + sq % 8]
                               << 3;
                    }
                }
            }

            score = ((short)score * phase + (score + 0x8000 >> 16) * (24 - phase)) / 24;

            int defaultSearch(int beta, int reduction = 1, bool nullAllowed = true) => score = -Search(ply + 1, depth - reduction, -beta, -alpha, nullAllowed);

            var (ttKey, ttMove, ttDepth, ttScore, ttFlag) = TT[key % 2097152];

            if (ttKey == key)
            {
                if (alpha == beta - 1 && ttDepth >= depth && ttFlag != (ttScore >= beta ? 0 : 2))
                    return ttScore;

                if (ttFlag != (ttScore > score ? 0 : 2))
                    score = ttScore;
            }

            else if (depth > 3)
                depth--;

            if (inQsearch)
            {
                if (score >= beta)
                    return score;

                if (score > alpha)
                    alpha = score;

                bestScore = score;
            }

            else if (doPruning)
            {
                if (depth < 7 && score - depth * 75 > beta)
                    return score;

                if (nullAllowed && score >= beta && depth > 2 && phase != 0)
                {
                    board.ForceSkipTurn();
                    defaultSearch(beta, 4 + depth / 6, false);
                    board.UndoSkipTurn();
                    if (score >= beta)
                        return beta;
                }
            }

            var (moves, quietsEvaluated, movesEvaluated) = (board.GetLegalMoves(inQsearch).OrderByDescending(move => move == ttMove ? 9_000_000_000_000_000_000
                                                                                                                   : move.IsCapture ? 1_000_000_000_000_000_000 * (long)GetPieceValue(board.GetPieceAt(move.NewPosition.File, move.NewPosition.Rank)) - (long)GetPieceValue(board.GetPieceAt(move.OriginalPosition.File, move.OriginalPosition.Rank))
                                                                                                                   : move == killers[ply] ? 500_000_000_000_000_000
                                                                                                                   : quietHistory[GetMoveHashCode(move) & 4095]),
                                                            new List<Move>(),
                                                            0);

            ttFlag = 0; // Upper

            foreach (var move in moves)
            {
                board.MakeMove(move);

                bool isQuiet = !move.IsCapture;

                if (inQsearch || movesEvaluated == 0
                || (depth <= 2 || movesEvaluated <= 4 || !isQuiet
                || defaultSearch(alpha + 1, 2 + depth / 8 + movesEvaluated / 16 + Convert.ToInt32(doPruning) - quietHistory[move.GetHashCode() & 4095].CompareTo(0)) > alpha) // TODO: Fix move.GetHashCode() to be compatible with original move.RawValue & 4095
                && alpha < defaultSearch(alpha + 1) && score < beta)
                    defaultSearch(beta);

                board.UndoMove(move);

                // If we are out of time, stop searching
                // if (timer.MillisecondsElapsedThisTurn > allocatedTime)
                //     return bestScore;

                movesEvaluated++;

                if (score > bestScore)
                {
                    bestScore = score;

                    if (score > alpha)
                    {
                        ttMove = move;
                        if (ply == 0) rootBestMove = move;
                        alpha = score;
                        ttFlag = 1; // Exact

                        if (score >= beta)
                        {
                            if (isQuiet)
                            {
                                quietHistory[GetMoveHashCode(move) & 4095] += depth * depth;

                                foreach (var previousMove in quietsEvaluated)
                                    quietHistory[GetMoveHashCode(previousMove) & 4095] -= depth * depth;
                                killers[ply] = move;
                            }

                            ttFlag++; // Lower

                            break;
                        }
                    }
                }

                if (isQuiet)
                    quietsEvaluated.Add(move);

                if (doPruning && quietsEvaluated.Count > 3 + depth * depth)
                    break;
            }

            if (movesEvaluated == 0)
                return inQsearch ? bestScore : inCheck ? ply - 1_000_000 : 0;

            TT[key % 2097152] = (key, ttMove, inQsearch ? 0 : depth, bestScore, ttFlag);

            return bestScore;
        }

        // Iterative deepening
        // for (; timer.MillisecondsElapsedThisTurn <= allocatedTime / 5 /* Soft time limit */; ++depth)
        //     // Aspiration windows
        //     for (int window = 40; ;)
        //     {
        //         int alpha = score - window,
        //             beta = score + window;
        //         // Search with the current window
        //         score = Search(0, depth, alpha, beta, false);

        //         // Hard time limit
        //         // if (timer.MillisecondsElapsedThisTurn > allocatedTime)
        //         //     break;

        //         // If the score is outside of the current window, we must research with a wider window.
        //         // Otherwise if we are in the window we can proceed to the next depth.
        //         if (alpha < score && score < beta)
        //             break;

        //         window *= 2;
        //     }

        // return rootBestMove;
        return Search(0, 6, -1_000_000_000, 1_000_000_000, false) == 0 ? new Move(new Position("a1"), new Position("a2"), Player.White) : rootBestMove; // Placeholder
    }

    private static int GetPieceTypeIndex(Piece piece)
        {
            int index = 0;
            if (piece.Owner == Player.Black) index += 6;

            switch (piece)
            {
                case ChessDotNet.Pieces.Pawn _ : return index + 0;
                case ChessDotNet.Pieces.Knight _ : return index + 1;
                case ChessDotNet.Pieces.Bishop _ : return index + 2;
                case ChessDotNet.Pieces.Rook _ : return index + 3;
                case ChessDotNet.Pieces.Queen _ : return index + 4;
                case ChessDotNet.Pieces.King _ : return index + 5;
                default: return 0; // Should not happen
            }
        }

        private static Type GetPieceTypeFromIndex(int pieceIndex)
        {
            switch (pieceIndex)
            {
                case 1: return typeof(ChessDotNet.Pieces.Pawn);
                case 2: return typeof(ChessDotNet.Pieces.Knight);
                case 3: return typeof(ChessDotNet.Pieces.Bishop);
                case 4: return typeof(ChessDotNet.Pieces.Rook);
                case 5: return typeof(ChessDotNet.Pieces.Queen);
                case 6: return typeof(ChessDotNet.Pieces.King);
                default: return null; // Should not happen
            }
        }
    {
        if (piece == null) return -1; // Handle null piece
        switch (piece)
        {
            case PieceType.Pawn: return 0;
            case PieceType.Knight: return 1;
            case PieceType.Bishop: return 2;
            case PieceType.Rook: return 3;
            case PieceType.Queen: return 4;
            case PieceType.King: return 5;
            default: return -1; // Should not happen
        }
    }

    private static int GetPieceValue(Piece piece)
    {
        if (piece == null) return 0;
        switch (piece)
        {
            case PieceType.Pawn: return 100;
            case PieceType.Knight: return 300;
            case PieceType.Bishop: return 300;
            case PieceType.Rook: return 500;
            case PieceType.Queen: return 900;
            case PieceType.King: return 10000; // King value is high for captures
            default: return 0;
        }
    }

    private static int GetMoveHashCode(Move move)
    {
        // A simple hash code for a move. This might not be unique enough for a strong engine,
        // but it's a starting point to replace move.RawValue.
        return move.OriginalPosition.GetHashCode() ^ move.NewPosition.GetHashCode();
    }

    static void Main(string[] args)
    {
        Hyper engine = new Hyper();
        string line;
        while ((line = Console.ReadLine()) != null)
        {
            string[] tokens = line.Split(' ');
            switch (tokens[0])
            {
                case "uci":
                    Console.WriteLine("id name Hyper");
                    Console.WriteLine("id author Manus AI");
                    Console.WriteLine("uciok");
                    break;
                case "isready":
                    Console.WriteLine("readyok");
                    break;
                case "ucinewgame":
                    engine = new Hyper(); // Reset engine for new game
                    break;
                case "position":
                    if (tokens[1] == "startpos")
                    {
                        engine._game = new ChessGame();
                    }
                    else if (tokens[1] == "fen")
                    {
                        string fen = string.Join(" ", tokens.Skip(2).Take(6));
                        engine._game = new ChessGame(fen);
                    }

                    if (tokens.Contains("moves"))
                    {
                        int movesIndex = Array.IndexOf(tokens, "moves") + 1;
                        for (int i = movesIndex; i < tokens.Length; i++)
                        {
                            string moveString = tokens[i];
                            // Convert UCI move string to File object
                            // This is a simplified conversion and might need more robust parsing
                            Position originalPos = new Position(moveString.Substring(0, 2));
                            Position newPos = new Position(moveString.Substring(2, 2));
                            char? promotion = null;
                            if (moveString.Length == 5)
                            {
                                promotion = moveString[4];
                            }
                            Move move = new Move(originalPos, newPos, engine._game.WhoseTurn, promotion);
                            engine._game.MakeMove(move, true);
                        }
                    }
                    engine._zobristKey = Zobrist.CalculateZobristKey(engine._game);
                    engine._positionHistory[engine._zobristKey] = engine._positionHistory.GetValueOrDefault(engine._zobristKey) + 1;
                    break;
                case "go":
                    int timeLimit = 10000; // Default time limit for thinking (10 seconds)
                    if (tokens.Contains("wtime") && engine._game.WhoseTurn == Player.White)
                    {
                        timeLimit = int.Parse(tokens[Array.IndexOf(tokens, "wtime") + 1]);
                    }
                    else if (tokens.Contains("btime") && engine._game.WhoseTurn == Player.Black)
                    {
                        timeLimit = int.Parse(tokens[Array.IndexOf(tokens, "btime") + 1]);
                    }
                    // For simplicity, we'll use a fixed depth search for now, as the original timer logic is complex.
                    // The original engine used iterative deepening with a soft and hard time limit.
                    // This needs to be reimplemented properly for a full UCI engine.
                    
                    BoardExtensions currentBoard = new BoardExtensions(engine._game, engine._positionHistory, engine._zobristKey);
                    Move bestMove = engine.Think(currentBoard, timeLimit);
                    Console.WriteLine($"bestmove {bestMove.OriginalPosition.ToString().ToLower()}{bestMove.NewPosition.ToString().ToLower()}{(bestMove.Promotion.HasValue ? bestMove.Promotion.Value.ToString().ToLower() : "")}");
                    break;
                case "quit":
                    return;
            }
        }
    }
}
