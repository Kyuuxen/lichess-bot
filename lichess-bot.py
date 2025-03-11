from lib.lichess_bot import start_program
import time

if __name__ == "__main__":
    start_program()  # Start the bot normally

    while True:  # Matchmaking loop
        print("🔄 Starting matchmaking...")  # Debugging

        try:
            game = session.search_game()  # Look for a game
            print(f"🔍 Game search result: {game}")  # Debugging

            if game is None:
                print("⏳ No game found, retrying in 10 seconds...")
                time.sleep(10)
                continue

            print("🎯 Game found! Playing now...")
            play_game(game)  # Play the game

            print("🏁 Game finished. Searching for a new game...")
            time.sleep(5)  # Short delay before searching again

        except Exception as e:
            print(f"🚨 Error: {e}, retrying in 10 seconds...")
            time.sleep(10)

