require "i18n/i18n"
require "utils/strings"
require "utils/logger"
require "cli/optionsparser"
require "cli/plugins"

class Application
  def initialize(options = {})
    Plugins.load_plugins( options[:sites] || Plugins.find_plugins() )

    @featuring_fix = options[:featuring_fix] || true
    @submit_plugin = nil
    @logger = Logger.new( "#{ENV["HOME"]}/.wikilyrics.log" )
    Plugins.all_plugins().each() do |plugin|
      plugin.cleanup_lyrics = options[:cleanup_lyrics] || true
      plugin.logger = @logger
      if plugin.plugin_name() == options[:submit]
        @submit_plugin = plugin
        @submit_plugin.set_submit_settings( options[:username],
                                            options[:password],
                                            options[:review] || true,
                                            options[:prompt_autogen] || false,
                                            options[:prompt_no_lyrics] || false)
      end
    end
  end

  def finalize()
    @logger.finalize() if @logger
  end

  def Application.notify( message )
    $stderr.puts "Wiki-Lyrics: " + message.gsub( /\/?<[^>]+>/, "" )
  end

  def notify( message )
    self.class.notify( message )
  end

  def restore_session( session_file )
    @submit_plugin.restore_session( session_file ) if @submit_plugin
  end

  def save_session( session_file )
    @submit_plugin.save_session( session_file ) if @submit_plugin
  end

  def fetch_lyrics( request )

    used_plugins = Plugins.all_plugins()

    response = nil
    response_plugin = nil
    submit_plugin_searched = false

    used_plugins.each() do |plugin|
      begin
        submit_plugin_searched = true if plugin == @submit_plugin
        response = plugin.lyrics_full_search( request )
        if response.lyrics
          response_plugin = plugin
          break
        end
      rescue TimeoutError
        notify( I18n.get( "cli.application.plugintimeout", plugin.plugin_name(), plugin.site_host() ) )
      end
    end

    return response, response_plugin

  end

  def fetch(artist, title, album = nil, year = nil)
    if @featuring_fix
      artist = Strings.cleanup_artist( artist, title )
      title  = Strings.cleanup_title( title )
    end

    request = Lyrics::Request.new( artist, title, album, year )
    response, response_plugin = fetch_lyrics( request )
    response
  end

  def process( artist, title, album, year )
    notify( I18n.get( "cli.application.searchinglyrics", title, artist ) )

    response = fetch(artist, title, album, year)

    if response.lyrics
      artist = response.artist ? response.artist : response.request.artist
      title = response.title ? response.title : response.request.title
      puts "\n#{response.lyrics}\n\n"
    else
      notify( I18n.get( "cli.application.nolyricsfound", request.title, request.artist ) )
    end

  end

end