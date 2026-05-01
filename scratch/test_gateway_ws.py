import asyncio
import websockets
import json

async def test_ws():
    uri = "ws://localhost:8005/symbol/ws/tutor/1/1/Starter"
    try:
        async with websockets.connect(uri) as websocket:
            print("Successfully connected to gateway WS!")
            # Wait a bit for a message
            try:
                msg = await asyncio.wait_for(websocket.recv(), timeout=2.0)
                print(f"Received: {msg}")
            except asyncio.TimeoutError:
                print("Connected but no message received yet (normal).")
    except Exception as e:
        print(f"Failed to connect: {e}")

if __name__ == "__main__":
    asyncio.run(test_ws())
