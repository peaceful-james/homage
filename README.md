# Homage

Homage is a transcript-to-audio converter built with Elixir/Phoenix. Upload or paste a transcript, and Homage will generate an MP3 file with distinct voices for each speaker.

## Prerequisites

### gTTS (Google Text-to-Speech)

This project uses [gTTS](https://gtts.readthedocs.io/) to generate MP3 audio files.

**Install via pip:**

```bash
pip install gTTS
# or
pip3 install gTTS
```

This installs both the Python library and the `gtts-cli` command-line tool.

**Verify installation:**

```bash
gtts-cli --version
# Should output something like: gtts-cli 2.x.x
```

**Troubleshooting:**

- If `gtts-cli` is not found after installation, ensure your Python scripts directory is in your `PATH`:

  ```bash
  # macOS/Linux - find where pip installs scripts
  python3 -m site --user-base
  # Add the bin subdirectory to your PATH, e.g.:
  export PATH="$HOME/.local/bin:$PATH"
  ```

- If you're using a Python virtual environment, activate it before running Homage
- On some systems, you may need to use `pip3` instead of `pip`

### ffmpeg (for audio concatenation and voice filtering)

Homage uses ffmpeg to concatenate audio segments and apply voice filters for speaker differentiation.

**macOS:**

```bash
brew install ffmpeg
```

**Linux (Debian/Ubuntu):**

```bash
sudo apt-get install ffmpeg
```

## Running Homage

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4028`](http://localhost:4028) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
