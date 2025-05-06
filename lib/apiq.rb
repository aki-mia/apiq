require 'optparse'
require 'json'
require 'net/http'
require 'uri'
require 'yaml'
require 'fileutils'

class Apiq
  CONFIG_PATH = File.join(Dir.home, ".apiq", "config.yml")

  def self.run(args)
    if args.empty? || ['-h', '--help'].include?(args[0])
      print_main_help
      return
    end

    case args[0]
    when 'config' then handle_config_command(args[1..])
    when 'gql'    then execute_graphql(args[1..])
    else              execute_api_request(args)
    end
  end

  def self.print_main_help
    puts <<~HELP
      apiq - Simple and powerful API CLI for developers

      USAGE:
        apiq METHOD PATH [options]        REST APIリクエスト
        apiq gql --file=query.graphql     GraphQLクエリ送信
        apiq config SUBCOMMAND [args]     プロファイル設定

      OPTIONS（共通）:
        --data=DATA               JSON文字列 または @ファイル名
        --header="Key: Value"     任意のヘッダー
        --cookie="a=b; c=d"       Cookie送信
        --content-type=TYPE       Content-Type変更
        --show-headers            レスポンスヘッダー表示
        --profile=NAME            プロファイル指定
        --token=TOKEN             Bearerトークン指定
        --base=URL                ベースURL指定
        --timeout=SECONDS         タイムアウト指定
        --verbose                 リクエスト詳細出力
        --only-status             HTTPステータスコードのみ出力
        --out=FILE                レスポンスボディをファイルに保存

      SUBCOMMANDS:
        config set NAME key=value ...
        config use NAME
        config show
        config clear
        gql --file=query.graphql

      詳細は README または `apiq config show` を参照
    HELP
  end

  def self.load_config
    FileUtils.mkdir_p(File.dirname(CONFIG_PATH))
    File.exist?(CONFIG_PATH) ? YAML.load_file(CONFIG_PATH) : { "default" => nil, "profiles" => {} }
  end

  def self.save_config(config)
    File.write(CONFIG_PATH, config.to_yaml)
  end

  def self.handle_config_command(args)
    cmd = args.shift

    if %w[-h --help].include?(cmd)
      puts <<~HELP
        USAGE: apiq config [COMMAND]

        COMMANDS:
          set PROFILE key=value ...    プロファイル追加/更新
          use PROFILE                  使用プロファイルに設定
          show                         現在の設定を表示
          clear                        設定ファイルを削除
      HELP
      return
    end

    config = load_config

    case cmd
    when "set"
      profile = args.shift
      config["profiles"][profile] ||= {}
      args.each do |arg|
        k, v = arg.split("=", 2)
        config["profiles"][profile][k] = v
      end
      save_config(config)
      puts "プロファイル '#{profile}' を更新しました。"
    when "use"
      profile = args.shift
      if config["profiles"].key?(profile)
        config["default"] = profile
        save_config(config)
        puts "デフォルトプロファイルを '#{profile}' に設定しました。"
      else
        puts "プロファイル '#{profile}' は存在しません。"
      end
    when "show"
      puts config.to_yaml
    when "clear"
      File.delete(CONFIG_PATH) if File.exist?(CONFIG_PATH)
      puts "設定を削除しました。"
    else
      puts "不明なconfigコマンドです。 `apiq config --help` を参照してください。"
    end
  end

  def self.execute_graphql(args)
    if args.include?('--help') || args.include?('-h')
      puts <<~HELP
        USAGE: apiq gql --file=QUERY.graphql [--profile=PROFILE]
      HELP
      return
    end

    options = {}
    OptionParser.new do |opts|
      opts.on("--file=FILE", "GraphQL query file") { |v| options[:file] = v }
      opts.on("--profile=PROFILE", "Profile name") { |v| options[:profile] = v }
    end.parse!(args)

    raise "GraphQLファイルが必要です" unless options[:file]
    query = File.read(options[:file])
    payload = { query: query }.to_json
    new_args = ['POST', '/graphql', '--data', payload]
    new_args += ["--profile", options[:profile]] if options[:profile]
    execute_api_request(new_args)
  end

  def self.execute_api_request(args)
    options = { headers: [], method: 'GET' }

    OptionParser.new do |opts|
      opts.on("--data=DATA", "Payload JSON or @file") { |v| options[:data] = v }
      opts.on("--base=URL", "Base URL") { |v| options[:base_url] = v }
      opts.on("--token=TOKEN", "Bearer token") { |v| options[:token] = v }
      opts.on("--profile=PROFILE", "Profile name") { |v| options[:profile] = v }
      opts.on("--header=HEADER", "Custom header key:value") { |v| options[:headers] << v }
      opts.on("--cookie=COOKIE", "Cookie string") { |v| options[:cookie] = v }
      opts.on("--content-type=TYPE", "Content-Type") { |v| options[:content_type] = v }
      opts.on("--show-headers", "Show response headers") { options[:show_headers] = true }
      opts.on("--verbose", "Show request detail") { options[:verbose] = true }
      opts.on("--timeout=SEC", Integer, "Request timeout") { |v| options[:timeout] = v }
      opts.on("--only-status", "Print only HTTP status code") { options[:only_status] = true }
      opts.on("--out=FILE", "Write response body to file") { |v| options[:out_file] = v }
      opts.on("-h", "--help", "Show help") do
        puts opts
        exit
      end
    end.parse!(args)

    method = args.shift&.upcase || 'GET'
    path   = args.shift || '/'

    config = load_config
    profile_name = options[:profile] || config["default"]
    profile = config["profiles"][profile_name] || {}

    base_url = options[:base_url] || profile["base_url"] || "http://localhost:3000"
    token    = options[:token] || profile["token"]
    uri = URI.join(base_url, path)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = options[:timeout] if options[:timeout]
    http.read_timeout = options[:timeout] if options[:timeout]

    klass = {
      "GET" => Net::HTTP::Get,
      "POST" => Net::HTTP::Post,
      "PUT" => Net::HTTP::Put,
      "DELETE" => Net::HTTP::Delete
    }[method] || Net::HTTP::Get

    request = klass.new(uri)
    request['Authorization'] = "Bearer #{token}" if token
    request['Cookie'] = options[:cookie] if options[:cookie]
    request['Content-Type'] = options[:content_type] || 'application/json'

    options[:headers].each do |h|
      k, v = h.split(":", 2)
      request[k.strip] = v.strip
    end

    if options[:data]
      request.body = options[:data].start_with?('@') ? File.read(options[:data][1..]) : options[:data]
    end

    if options[:verbose]
      puts "> #{method} #{uri}"
      puts "> Headers:"
      request.each_header { |k, v| puts "  #{k}: #{v}" }
      puts "> Body:\n#{request.body}" if request.body
    end

    response = http.request(request)

    if options[:only_status]
      puts response.code
      return
    end

    if options[:show_headers]
      puts "HTTP/#{response.http_version} #{response.code} #{response.message}"
      response.each_header { |k, v| puts "#{k}: #{v}" }
      puts
    end

    if options[:out_file]
      File.write(options[:out_file], response.body)
      puts "レスポンスを #{options[:out_file]} に保存しました。"
    else
      begin
        puts JSON.pretty_generate(JSON.parse(response.body))
      rescue
        puts response.body
      end
    end
  end
end
