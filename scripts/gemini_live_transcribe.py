#!/usr/bin/env python3
"""
Gemini 3.5 Transcribe Live - Real-Time Bidirectional Speech-to-Text
Uses Google GenAI Live API with model "gemini-3.5-transcribe-live".

Supports:
- Live interim hypotheses preview (real-time captions)
- Finalized transcripts (input_transcription)
- Automatic language detection across 85+ languages
- Streaming from audio file or live microphone
- Standalone execution or local WebSocket relay server
"""

import argparse
import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Optional

try:
    from google import genai
    from google.genai import types
except ImportError:
    print("Error: 'google-genai' package is not installed.")
    print("Please run: pip install google-genai")
    sys.exit(1)

DEFAULT_MODEL = "gemini-3.5-transcribe-live"

# Common Hindi grocery & POS vocabulary mapping to Roman Hinglish
_WORD_DICT = {
    'बासमती': 'basmati', 'चावल': 'chawal', 'आटा': 'aata', 'मैदा': 'maida', 'सूजी': 'sooji',
    'दाल': 'dal', 'चीनी': 'cheeni', 'शक्कर': 'sakhar', 'नमक': 'namak', 'तेल': 'tel', 'घी': 'ghee',
    'हल्दी': 'haldi', 'मिर्च': 'mirch', 'धनिया': 'dhaniya', 'जीरा': 'jeera', 'दूध': 'doodh',
    'दही': 'dahi', 'पनीर': 'paneer', 'ब्रेड': 'bread', 'अंडा': 'anda', 'अंडे': 'ande',
    'चाय': 'chai', 'कॉफी': 'coffee', 'बिस्कुट': 'biscuit', 'क्रंचीस': 'crunchies',
    'नमकीन': 'namkeen', 'चिप्स': 'chips', 'मैगी': 'maggi', 'साबुन': 'sabun', 'सर्फ': 'surf',
    'किलो': 'kilo', 'लीटर': 'litre', 'ग्राम': 'gm', 'पैकेट': 'packet', 'पीस': 'piece',
    'रुपये': 'rs', 'रुपए': 'rs', 'रुपया': 'rs', 'रु': 'rs', '₹': 'rs',
    'नकद': 'cash', 'उधार': 'udhar', 'खाता': 'khata', 'एक': '1', 'दो': '2', 'तीन': '3',
    'चार': '4', 'पांच': '5', 'दस': '10', 'सौ': '100', 'हजार': '1000',
    'आधा': 'aadha', 'पाव': 'paav', 'डेढ़': 'dedh', 'ढाई': 'dhai',
}

_DEV_DIGITS = str.maketrans('०१२३४५६७८९', '0123456789')

def to_hinglish(text: str) -> str:
    """Converts Devanagari Hindi text to clean Romanized Hinglish."""
    if not text:
        return text
    # 1. Numerals
    text = text.translate(_DEV_DIGITS)
    text = text.replace('₹', ' rs ').replace('।', ' , ')
    # 2. Dictionary replacements
    for dev, rom in _WORD_DICT.items():
        text = text.replace(dev, rom)
    # 3. Clean price representations (e.g. 100 rs -> 100rs)
    import re
    text = re.sub(r'(\d+(?:\.\d+)?)\s*(?:rs|rupaye|rupees|rupe|rupya)\b', r'\1rs', text, flags=re.IGNORECASE)
    text = re.sub(r'\s+', ' ', text).strip()
    return text


def build_live_config(
    language_codes: Optional[list[str]] = None,
    mode: str = "SMART",
) -> types.LiveConnectConfig:
    """Builds the LiveConnectConfig for live speech transcription."""
    return types.LiveConnectConfig(
        response_modalities=["TEXT"],
        input_audio_transcription=types.AudioTranscriptionConfig(
            language_codes=language_codes or ["en", "hi"],  # Bilingual capture Romanized to Hinglish
            mode=mode,  # SMART (disfluency removal) or VERBATIM
        ),
    )


async def live_transcribe_file(
    file_path: str,
    api_key: Optional[str] = None,
    model: str = DEFAULT_MODEL,
    chunk_size_bytes: int = 4096,
    chunk_delay_sec: float = 0.05,
):
    """Streams an audio file (WAV or raw PCM 16-bit 16kHz) to Gemini 3.5 Transcribe Live."""
    api_key = api_key or os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("Error: Gemini API Key is required. Set GEMINI_API_KEY environment variable or pass --api-key.")
        return

    client = genai.Client(api_key=api_key)
    config = build_live_config()

    path = Path(file_path)
    if not path.exists():
        print(f"Error: File not found: {file_path}")
        return

    audio_bytes = path.read_bytes()
    # Strip 44-byte WAV header if present
    if audio_bytes.startswith(b"RIFF") and len(audio_bytes) > 44:
        raw_pcm = audio_bytes[44:]
    else:
        raw_pcm = audio_bytes

    print(f"Connecting to Gemini Live Transcription ({model})...")
    async with client.aio.live.connect(model=model, config=config) as session:
        print("Connected! Streaming audio chunks...")

        async def send_audio():
            try:
                for i in range(0, len(raw_pcm), chunk_size_bytes):
                    chunk = raw_pcm[i : i + chunk_size_bytes]
                    await session.send_realtime_input(
                        audio=types.Blob(data=chunk, mime_type="audio/pcm;rate=16000")
                    )
                    await asyncio.sleep(chunk_delay_sec)
                # Indicate end of audio stream
                await session.send_realtime_input(audio_stream_end=True)
            except asyncio.CancelledError:
                pass
            except Exception as e:
                print(f"Audio send error: {e}")

        async def receive_transcripts():
            try:
                async for response in session.receive():
                    server_content = response.server_content
                    if not server_content:
                        continue

                    # Real-time interim preview for live captions (Hinglish)
                    if server_content.interim_input_transcription:
                        interim_text = server_content.interim_input_transcription.text
                        if interim_text:
                            print(f"\r[Interim] {to_hinglish(interim_text)}", end="", flush=True)

                    # Finalized transcript (Hinglish)
                    if server_content.input_transcription:
                        final_text = server_content.input_transcription.text
                        if final_text:
                            print(f"\n[Final] {to_hinglish(final_text)}")

                    # Model response text (if any)
                    if server_content.model_turn:
                        for part in server_content.model_turn.parts:
                            if part.text:
                                print(f"\n[AI]: {to_hinglish(part.text)}")
            except asyncio.CancelledError:
                pass
            except Exception as e:
                print(f"\nReceive error: {e}")

        sender_task = asyncio.create_task(send_audio())
        receiver_task = asyncio.create_task(receive_transcripts())

        await sender_task
        # Allow extra time for final hypothesis reception
        await asyncio.sleep(2.0)
        receiver_task.cancel()
        print("\nStreaming finished.")


async def live_transcribe_mic(
    api_key: Optional[str] = None,
    model: str = DEFAULT_MODEL,
):
    """Streams live microphone audio directly to Gemini 3.5 Transcribe Live."""
    try:
        import pyaudio
    except ImportError:
        print("PyAudio is not installed. To record from microphone directly in Python, run:")
        print("  pip install pyaudio")
        print("\nNote: The Flutter POS software records microphone directly in Dart via native audio recorder.")
        return

    api_key = api_key or os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("Error: Gemini API Key is required. Set GEMINI_API_KEY or use --api-key.")
        return

    client = genai.Client(api_key=api_key)
    config = build_live_config()

    p = pyaudio.PyAudio()
    rate = 16000
    chunk = 1024
    stream = p.open(
        format=pyaudio.paInt16,
        channels=1,
        rate=rate,
        input=True,
        frames_per_buffer=chunk,
    )

    print(f"Connecting to Gemini Live Transcription ({model})...")
    async with client.aio.live.connect(model=model, config=config) as session:
        print("Connected to Live Transcription! Speak into microphone (Ctrl+C to stop)...")

        async def send_mic():
            loop = asyncio.get_running_loop()
            try:
                while True:
                    data = await loop.run_in_executor(None, stream.read, chunk, False)
                    await session.send_realtime_input(
                        audio=types.Blob(data=data, mime_type="audio/pcm;rate=16000")
                    )
            except asyncio.CancelledError:
                pass

        async def receive_transcripts():
            try:
                async for response in session.receive():
                    server_content = response.server_content
                    if not server_content:
                        continue

                    # Real-time interim preview for live captions (Hinglish)
                    if server_content.interim_input_transcription:
                        interim_text = server_content.interim_input_transcription.text
                        if interim_text:
                            print(f"\r[Interim] {to_hinglish(interim_text)}", end="", flush=True)

                    # Finalized transcript (Hinglish)
                    if server_content.input_transcription:
                        final_text = server_content.input_transcription.text
                        if final_text:
                            print(f"\n[Final] {to_hinglish(final_text)}")
            except asyncio.CancelledError:
                pass

        sender_task = asyncio.create_task(send_mic())
        receiver_task = asyncio.create_task(receive_transcripts())

        try:
            await asyncio.gather(sender_task, receiver_task)
        except KeyboardInterrupt:
            sender_task.cancel()
            receiver_task.cancel()
        finally:
            stream.stop_stream()
            stream.close()
            p.terminate()


def main():
    parser = argparse.ArgumentParser(description="Gemini 3.5 Transcribe Live Real-time STT")
    parser.add_argument("--api-key", help="Google Gemini API Key")
    parser.add_argument("--file", help="Path to audio file (WAV or 16-bit PCM 16kHz)")
    parser.add_argument("--mic", action="store_true", help="Stream live microphone input")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Gemini live model name (default: {DEFAULT_MODEL})")
    args = parser.parse_args()

    if args.file:
        asyncio.run(live_transcribe_file(args.file, api_key=args.api_key, model=args.model))
    elif args.mic:
        asyncio.run(live_transcribe_mic(api_key=args.api_key, model=args.model))
    else:
        # Default test loop matching user snippet
        print(f"Gemini 3.5 Transcribe Live Ready. Model: {args.model}")
        print("Usage:")
        print("  python scripts/gemini_live_transcribe.py --file path/to/sample.wav")
        print("  python scripts/gemini_live_transcribe.py --mic")


if __name__ == "__main__":
    main()
