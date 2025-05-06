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

## Advanced Tips

- Use `.env` for sensitive tokens
- Combine with `jq` for JSON filtering
- Works great with `mise`, `direnv`

MIT License
