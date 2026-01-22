defmodule Homage.EdgeTTS do
  @moduledoc """
  Use `edge-tts` to speak a transcript in multiple voices.

  **NOTE:** This module is not currently in use. The application now uses
  `Homage.GTTS` for text-to-speech. This module is kept for potential future use
  as edge-tts offers a wider variety of neural voices.

  To use edge-tts, install it via: `pip install edge-tts`
  """

  def speak_text_to_file(text_to_speak, speaker_number, file_name) do
    speaker = Enum.at(my_voice_picks(), speaker_number - 1) || "en-US-SaraNeural"

    # Properly escape the text for shell command
    escaped_text = escape_for_shell(text_to_speak)

    command =
      "edge-tts --voice \"#{speaker}\" --write-media #{file_name} --text #{escaped_text}"

    case System.cmd("sh", ["-c", command]) do
      {_, 0} ->
        {:ok, file_name}

      {error_message, _exit_code} ->
        {:error, "Failed to generate audio: #{error_message}"}
    end
  end

  defp escape_for_shell(text) do
    # Use single quotes and escape any single quotes in the text
    # by replacing ' with '\''
    escaped = String.replace(text, "'", "'\\''")
    "'#{escaped}'"
  end

  def my_voice_picks do
    [
      "en-US-SaraNeural",
      "en-US-BrianNeural",
      "en-US-CoraNeural",
      "en-US-RyanMultilingualNeural",
      "en-US-AriaNeural",
      "en-US-KaiNeural"
    ]
  end

  @voices_map %{
    "en-US-SaraNeural" => {"Female", "Sincere, Calm, Confident"},
    "en-US-BrianNeural" => {"Male", "Sincere, Calm, Approachable"},
    "en-US-CoraNeural" => {"Female", "Empathetic, Formal, Sincere"},
    "en-US-RyanMultilingualNeural" => {"Male", "Professional, Authentic, Sincere"},
    "en-US-AriaNeural" => {"Female", "Crisp, Bright, Clear"},
    "en-US-KaiNeural" => {"Male", "Sincere, Pleasant, Bright, Clear, Friendly, Warm"},
    "en-US-AIGenerate1Neural" => {"Male", "Serious, Clear, Formal"},
    "en-US-AIGenerate2Neural" => {"Female", "Serious, Mature, Formal"},
    "en-US-AdamMultilingualNeural" => {"Male", "warm, engaging, deep"},
    "en-US-AlloyTurboMultilingualNeural" => {"Male", "Versatile"},
    "en-US-AmandaMultilingualNeural" => {"Female", "clear, bright, youthful"},
    "en-US-AmberNeural" => {"Female", "Whimsical, Upbeat, Light-Hearted"},
    "en-US-AnaNeural" => {"Female", "Curious, Cheerful, Engaging"},
    "en-US-AndrewMultilingualNeural" => {"Male", "Confident, Casual, Warm"},
    "en-US-AndrewNeural" => {"Male", "Confident, Authentic, Warm"},
    "en-US-AshTurboMultilingualNeural" => {"Male", ""},
    "en-US-AshleyNeural" => {"Female", "Sincere, Approachable, Honest"},
    "en-US-AvaMultilingualNeural" => {"Female", "Pleasant, Friendly, Caring"},
    "en-US-AvaNeural" => {"Female", "Pleasant, Caring, Friendly"},
    "en-US-BlueNeural" => {"Neutral", "Formal, Serious, Confident"},
    "en-US-BrandonMultilingualNeural" => {"Male", "Warm, Engaging, Authentic"},
    "en-US-BrandonNeural" => {"Male", "Warm, Engaging, Authentic"},
    "en-US-BrianMultilingualNeural" => {"Male", "Sincere, Calm, Approachable"},
    "en-US-ChristopherMultilingualNeural" => {"Male", "Deep, Warm"},
    "en-US-ChristopherNeural" => {"Male", "Deep, Warm"},
    "en-US-CoraMultilingualNeural" => {"Female", "Empathetic, Formal, Sincere"},
    "en-US-DavisMultilingualNeural" => {"Male", "soothing, calm, smooth"},
    "en-US-DavisNeural" => {"Male", "Soothing, Calm, Smooth"},
    "en-US-DerekMultilingualNeural" => {"Male", "confident, knowledgable, formal"},
    "en-US-DustinMultilingualNeural" => {"Male", "youthful, clear, thoughtful"},
    "en-US-EchoTurboMultilingualNeural" => {"Male", ""},
    "en-US-ElizabethNeural" => {"Female", "Authoritative, Formal, Serious"},
    "en-US-EmmaMultilingualNeural" => {"Female", "Cheerful, Light-Hearted, Casual"},
    "en-US-EmmaNeural" => {"Female", "Cheerful, Light-Hearted, Casual"},
    "en-US-EricNeural" => {"Male", "Confident, Sincere, Warm"},
    "en-US-EvelynMultilingualNeural" => {"Female", "Youthful, Crisp, Upbeat"},
    "en-US-FableTurboMultilingualNeural" => {"Neutral", ""},
    "en-US-GuyNeural" => {"Male", "Light-Hearted, Whimsical, Friendly"},
    "en-US-JacobNeural" => {"Male", "Sincere, Formal, Confident"},
    "en-US-JaneNeural" => {"Female", "Serious, Approachable, Upbeat"},
    "en-US-JasonNeural" => {"Male", "Gentle, Shy, Polite"},
    "en-US-JennyMultilingualNeural" => {"Female", "Sincere, Pleasant, Approachable"},
    "en-US-JennyNeural" => {"Female", "Sincere, Pleasant, Approachable"},
    "en-US-LewisMultilingualNeural" => {"Male", "knowledgable, formal, confident"},
    "en-US-LolaMultilingualNeural" => {"Female", "sincere, calm, warm"},
    "en-US-LunaNeural" => {"Female", "Sincere, Pleasant, Bright, Clear, Friendly, Warm"},
    "en-US-MichelleNeural" => {"Female", "Confident, Authentic, Warm"},
    "en-US-MonicaNeural" => {"Female", "Mature, Authentic, Warm"},
    "en-US-NancyMultilingualNeural" => {"Female", "casual, youthful, approachable"},
    "en-US-NancyNeural" => {"Female", "Confident, Serious, Mature"},
    "en-US-NovaTurboMultilingualNeural" => {"Female", "Deep, Resonant"},
    "en-US-OnyxTurboMultilingualNeural" => {"Male", ""},
    "en-US-PhoebeMultilingualNeural" => {"Female", "youthful, upbeat, confident"},
    "en-US-RogerNeural" => {"Male", "Serious, Formal, Confident"},
    "en-US-SamuelMultilingualNeural" => {"Male", "sincere, warm, expressive"},
    "en-US-SerenaMultilingualNeural" => {"Female", "formal, confident, mature"},
    "en-US-ShimmerTurboMultilingualNeural" => {"Female", ""},
    "en-US-SteffanMultilingualNeural" => {"Male", "Casual, Thoughtful"},
    "en-US-SteffanNeural" => {"Male", "Mature, Authentic, Warm"},
    "en-US-TonyNeural" => {"Male", "Thoughtful, Authentic, Sincere"}
  }
  @voices_list Map.keys(@voices_map)

  def voices_map, do: @voices_map
  def voices_list, do: @voices_list
end
