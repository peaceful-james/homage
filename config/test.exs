import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :homage, HomageWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "WoJL5jZ/O+Xig852QVvRmRTL329tPce936Jr3IH/Unmp/5G+/256o+tmev3Db9I2",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
