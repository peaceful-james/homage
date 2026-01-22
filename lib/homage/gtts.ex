defmodule Homage.GTTS do
  @moduledoc """
  Use gTTS (gtts-cli) to speak transcript text into mp3 files.
  Speaker voices are approximated via tld selection and optional ffmpeg filters.
  """

  require Logger

  @default_profile %{tld: "com", slow: false, ffmpeg_filter: nil}
  @speaker_profiles [
    @default_profile,
    %{
      tld: "co.uk",
      slow: false,
      ffmpeg_filter: "asetrate=44100*1.04,aresample=44100,atempo=0.9615"
    },
    %{
      tld: "com.au",
      slow: false,
      ffmpeg_filter: "asetrate=44100*0.96,aresample=44100,atempo=1.0417"
    },
    %{tld: "ca", slow: false, ffmpeg_filter: "atempo=0.95"},
    %{tld: "co.in", slow: false, ffmpeg_filter: "atempo=1.05"}
  ]

  @spec speak_text_to_file(String.t(), integer() | nil, String.t()) ::
          {:ok, String.t()} | {:error, String.t()}
  def speak_text_to_file(text_to_speak, speaker_number, file_name) do
    profile = speaker_profile(speaker_number)

    case command_for_gtts() do
      {:error, reason} ->
        {:error, reason}

      {:ok, runner} ->
        temp_path =
          Path.join(System.tmp_dir!(), "homage_tts_#{System.unique_integer([:positive])}.txt")

        try do
          File.write!(temp_path, text_to_speak)

          case run_gtts(runner, temp_path, file_name, profile) do
            {_, 0} ->
              case File.stat(file_name) do
                {:ok, %File.Stat{size: size}} when size > 0 ->
                  case maybe_apply_voice_filter(file_name, profile) do
                    :ok -> {:ok, file_name}
                    {:error, reason} -> {:error, reason}
                  end

                {:ok, _} ->
                  {:error, "gTTS output file is empty: #{file_name}"}

                {:error, _} ->
                  {:error, "gTTS finished but output file missing: #{file_name}"}
              end

            {error_message, _exit_code} ->
              {:error, "Failed to generate audio: #{String.trim(error_message)}"}
          end
        rescue
          exception ->
            {:error, Exception.message(exception)}
        after
          _ = File.rm(temp_path)
        end
    end
  end

  defp speaker_profile(nil), do: @default_profile

  defp speaker_profile(speaker_number) when is_integer(speaker_number) do
    profiles = @speaker_profiles

    index =
      speaker_number
      |> max(1)
      |> Kernel.-(1)
      |> rem(length(profiles))

    Enum.at(profiles, index) || @default_profile
  end

  defp speaker_profile(_), do: @default_profile

  defp command_for_gtts do
    cond do
      executable = System.find_executable("gtts-cli") ->
        {:ok, {:gtts_cli, executable}}

      executable = System.find_executable("python3") ->
        {:ok, {:python, executable}}

      executable = System.find_executable("python") ->
        {:ok, {:python, executable}}

      true ->
        {:error, "gtts-cli not found. Install with: pip3 install gTTS"}
    end
  end

  defp run_gtts({:gtts_cli, executable}, text_path, file_name, profile) do
    base_args = ["-f", text_path, "--output", file_name, "--tld", profile.tld]
    args = if profile.slow, do: base_args ++ ["--slow"], else: base_args

    System.cmd(executable, args, stderr_to_stdout: true)
  end

  defp run_gtts({:python, executable}, text_path, file_name, profile) do
    script = """
    import sys
    from gtts import gTTS

    text_path = sys.argv[1]
    out_path = sys.argv[2]
    tld = sys.argv[3]
    slow = sys.argv[4].lower() == "true"

    with open(text_path, "r", encoding="utf-8") as f:
        text = f.read()

    gTTS(text=text, tld=tld, slow=slow).save(out_path)
    """

    System.cmd(
      executable,
      ["-c", script, text_path, file_name, profile.tld, to_string(profile.slow)],
      stderr_to_stdout: true
    )
  end

  defp maybe_apply_voice_filter(_file_name, %{ffmpeg_filter: nil}), do: :ok

  defp maybe_apply_voice_filter(file_name, %{ffmpeg_filter: filter}) do
    case System.find_executable("ffmpeg") do
      nil ->
        {:error, "ffmpeg not found (required for voice filtering)"}

      _ ->
        filtered_path = file_name <> ".filtered"

        case System.cmd("ffmpeg", ["-y", "-i", file_name, "-filter:a", filter, filtered_path],
               stderr_to_stdout: true
             ) do
          {_, 0} ->
            with :ok <- File.rm(file_name),
                 :ok <- File.rename(filtered_path, file_name) do
              :ok
            else
              _ ->
                Logger.warn("Failed to swap filtered audio for #{file_name}")
                :ok
            end

          {error_message, _exit_code} ->
            _ = File.rm(filtered_path)
            Logger.warn("Failed to apply voice filter: #{String.trim(error_message)}")
            :ok
        end
    end
  end
end
