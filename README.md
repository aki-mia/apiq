# apiq

I made it for studying `Ruby`.

[![Homebrew](https://img.shields.io/badge/homebrew-install-brightgreen)](https://github.com/aki-mia/homebrew-apiq)
[![mise](https://img.shields.io/badge/mise-install-brightgreen)](https://mise.jdx.dev/)
[![Ruby](https://img.shields.io/badge/ruby-%3E=3.3-red)](https://www.ruby-lang.org/en/)

**A developer-friendly CLI for making REST and GraphQL API requests.**
Supports profiles, headers, cookies, file uploads, logging, and more.

## Features

- Simple `curl` alternative in Ruby
- REST + GraphQL support
- Profile switching (`dev`, `stg`, `prod`, etc.)
- Custom headers, cookies, and content types
- Pretty-printed JSON response
- Save response body to file
- CLI-friendly: `--only-status`, `--verbose`, etc.

## Install via Homebrew

```bash
brew tap aki-mia/apiq
brew install apiq
```

## Basic Usage

```bash
apiq get /users
apiq post /login --data '{"user":"foo"}'
apiq gql --file query.graphql
```

## Common Options

- `--header "X-Foo: Bar"`
- `--cookie "token=abc123"`
- `--profile dev`
- `--token abc123`
- `--base http://localhost:3000`
- `--content-type text/plain`
- `--show-headers`
- `--timeout 5`
- `--only-status`
- `--out result.json`
- `--verbose`

## Config Usage

```bash
apiq config set dev base_url=http://localhost:3000 token=abc123
apiq config use dev
apiq config show
```

## 🔧 For Developers: Run Locally Before Homebrew Packaging

Want to test `apiq` locally before publishing it via Homebrew? Here's how.

### 1. Clone or Download

```bash
git clone https://github.com/YOURNAME/apiq.git
cd apiq
```

Or unzip the project into a working directory.

### 2. Install Dependencies

```bash
brew install mise
mise i
bundle install
```

### 3. Ensure Executable

```bash
chmod +x bin/apiq
```

### 4. Set Up Configuration

```bash
bin/apiq config set dev base_url=http://localhost:3000 token=abc123
bin/apiq config use dev
```

Or create `~/.apiq/config.yml` manually:

```yaml
default: dev
profiles:
  dev:
    base_url: "http://localhost:3000"
    token: "abc123"
```

### 5. Try It!

```bash
bin/apiq get /status --show-headers --verbose
```

Or with a public API:

```bash
bin/apiq get https://httpbin.org/get
bin/apiq post https://httpbin.org/post --data '{"test":"yes"}'
```

### 6. Optional: Add to PATH

```bash
echo 'export PATH="$HOME/path/to/apiq/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
apiq get /ping
```

## 🛠️ Releasing to Homebrew (For Maintainers)

This section explains how to manually package and publish a new version of `apiq` for Homebrew distribution.

### 1. Create a Release Archive (`.tar.gz`)

Run the following from the project root:

```bash
mkdir -p release
tar -czvf release/apiq-0.1.0.tar.gz bin lib
```

This creates a compressed archive with the `bin/` and `lib/` directories. Do **not** include `config.yml`.

---

### 2. Generate SHA256 Checksum

```bash
curl -L -o apiq.tar.gz https://github.com/aki-mia/apiq/archive/refs/tags/v0.1.0.tar.gz
shasum -a 256 apiq.tar.gz
```

Example output:

```
7a1c894d0f0e12c8b012df5c82a537a65d0e7f71c242fca0f0f734fab63f72b1  release/apiq-0.1.0.tar.gz
```

Copy the hash value (the first part of the output).

---

### 3. Update the Homebrew Formula

Edit `homebrew-apiq/Formula/apiq.rb`:

```ruby
class Apiq < Formula
  desc "A powerful and easy-to-use API CLI tool for developers"
  homepage "https://github.com/YOURNAME/apiq"
  url "https://github.com/YOURNAME/apiq/releases/download/v0.1.0/apiq-0.1.0.tar.gz"
  sha256 "your-computed-sha256-hash"
  version "0.1.0"

  depends_on "ruby"

  def install
    bin.install "bin/apiq"
    lib.install Dir["lib/*"]
  end

  test do
    system "#{bin}/apiq", "--help"
  end
end
```

---

### 4. Commit and Push the Formula

```bash
git add Formula/apiq.rb
git commit -m "Update Formula for v0.1.0"
git push origin main
```

Once merged into the `main` branch, Homebrew users will be able to install it via:

```bash
brew untap aki-mia/apiq || true
brew tap aki-mia/apiq
brew install apiq
```

## Advanced Tips

- Use `.env` for sensitive tokens
- Combine with `jq` for JSON filtering
- Works great with `mise`, `direnv`

MIT License
