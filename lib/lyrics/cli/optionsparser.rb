# Copyright (C) 2006-2008 by Sergio Pistone
# sergio_pistone@yahoo.com.ar
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

require File.expand_path( File.dirname( __FILE__ ) + "/../i18n/i18n" )
require File.expand_path( File.dirname( __FILE__ ) + "/plugins" )
require File.expand_path( File.dirname( __FILE__ ) + "/../mediawikilyrics" )

require "optparse"
require "ostruct"
require "uri"

WIKILYRICS_VERSION = "Wiki-Lyrics v#{MediaWikiLyrics.version()}"
TOOLKITS_DEFAULT = ["qt3", "qt4", "gtk", "tk"]

module OptionsParser

	@@max_chunksize = 80
	begin
		require "curses"
		@@max_chunksize = Curses::Window.new( 0, 0, 0, 0 ).maxx() - 38
		Curses::close_screen()
	rescue Exception
		@@max_chunksize = 80
	end

	def self.get_text_chunk( text, start_idx )

		# find first non empty character in chunk:
		while ( start_idx < (text.size-1) && "\n ".index( text[start_idx] ) )
			start_idx += 1
		end

		# no more chunks left
		return nil if start_idx >= text.size

		# buscar el ultimo " " o el primer "\n "
		end_idx = nil
		idx = start_idx
		while ( idx < text.size && idx < start_idx + @@max_chunksize + 1 )
			if text[idx] == "\n"[0]
				end_idx = idx
				break
			elsif text[idx] == " "[0]
				end_idx = idx
			end
			idx += 1
		end
		end_idx = idx if ! end_idx || idx == text.size
		return text.slice( start_idx..end_idx-1 ), end_idx

	end

	def self.split( text )
		ret = []
		start_idx = 0
		loop do
      chunk, start_idx = get_text_chunk( text, start_idx )
      break if !chunk
			ret << chunk
		end
		return ret
	end

	def self.parse( args )

		opts = OpenStruct.new()
		opts.cleanup = true
		opts.feat_fix = true
		opts.meta = true
		opts.sites = ["Lyriki", "LyricWiki"]
		opts.submit = nil
		opts.review = true
		opts.prompt_autogen = false
		opts.prompt_no_lyrics = false
		opts.proxy = nil
		opts.toolkits = TOOLKITS_DEFAULT

		parser = OptionParser.new() do |parser|
			parser.banner = I18n.get( "cli.usage", "wikilyrics.rb" )
 			parser.separator I18n.get( "cli.description" )

			parser.separator ""
			parser.separator I18n.get( "cli.options" )
			parser.on( "-a", "--artist [ARTIST]", *split( I18n.get( "cli.options.artist", "batch-file" ) ) ) do |artist|
				opts.artist = artist
			end
			parser.on( "-t", "--title [TITLE]", *split( I18n.get( "cli.options.title", "batch-file" ) ) ) do |title|
				opts.title = title
			end
			parser.on( "-l", "--album [ALBUM]", *split( I18n.get( "cli.options.album" ) ) ) { |album| opts.album = album }
			parser.on( "-y", "--year [YEAR]", *split( I18n.get( "cli.options.year" ) ) ) { |year| opts.year = year }
			parser.on( "-f", "--[no-]featfix", *split( I18n.get( "cli.options.featfix", I18n.get( "cli.values.true" ) ) ) ) do |feat_fix|
				opts.feat_fix = feat_fix
			end

			parser.separator ""
			parser.on( "-b", "--batch-file [FILE]", *split( I18n.get( "cli.options.batchfile" ) ) ) do |batch_file|
				opts.batch_file = batch_file
			end

			parser.separator ""
			parser.on( "-c", "--[no-]cleanup", *split( I18n.get( "cli.options.cleanup", I18n.get( "cli.values.true" ) ) ) ) do |cleanup|
				opts.cleanup = cleanup
			end
			parser.separator ""
			parser.on( "--sites [SITE1,SITE2...]", Array, *split( I18n.get( "cli.options.sites", opts.sites.join( "," ), "sites-list" ) ) ) { |sites| opts.sites = sites }
			parser.on( "--sites-list", *split( I18n.get( "cli.options.sites.list" ) ) ) do
				puts I18n.get( "cli.options.sites.list.available" )
				Plugins.load_plugins( Plugins.find_plugins() )
				plugins = Plugins.all_plugins().sort { |a,b| a.class.name <=> b.class.name }
				plugins.each() { |plugin| puts " - #{plugin.class.name.slice(12..-1)} (#{plugin.site_host})" }
				exit
			end

			parser.separator ""
			parser.on( "-s", "--submit [Lyriki|LyricWiki]", *split( I18n.get( "cli.options.submit", "username", "password" ) ) ) do |submit|
				opts.submit = submit
			end
			parser.on( "-u", "--username [USERNAME]", *split( I18n.get( "cli.options.username", "submit" ) ) ) do |username|
				opts.username = username
			end
			parser.on( "-p", "--password [PASSWORD]", *split( I18n.get( "cli.options.password", "submit" ) ) ) do |password|
				opts.password = password
			end
			parser.on( "--persist [SESSIONFILE]", *split( I18n.get( "cli.options.persist", "username", "password" ) ) ) do |file|
				opts.session_file = file
			end

			parser.on( "-r", "--[no-]review", *split( I18n.get( "cli.options.prompt.review", I18n.get( "cli.values.true" ), "submit" ) ) ) { |review| opts.review = review }
			parser.on( "-g", "--[no-]autogen", *split( I18n.get( "cli.options.prompt.autogen", I18n.get( "cli.values.false" ), "review" ) ) ) { |autogen| opts.prompt_autogen = autogen }
			parser.on( "-n", "--[no-]new", *split( I18n.get( "cli.options.prompt.nolyrics", I18n.get( "cli.values.false" ), "review" ) ) ) { |prompt_no_lyrics| opts.prompt_no_lyrics = prompt_no_lyrics }

			parser.separator ""
			parser.on( "-x", "--proxy [PROXY]", *split( I18n.get( "cli.options.proxy" ) ) ) { |proxy| opts.proxy = proxy }

			parser.separator ""
			parser.on( "-k", "--toolkits [TK1,TK2...]", Array, *split( I18n.get( "cli.options.toolkits", TOOLKITS_DEFAULT.join( "," ) ) ) ) { |toolkits| opts.toolkits = toolkits ? toolkits : [] }

			parser.separator ""
			parser.on_tail( "-h", "--help", *split( I18n.get( "cli.options.help" ) ) ) { puts parser; exit }
			parser.on_tail( "-v", "--version", *split( I18n.get( "cli.options.version" ) ) ) { puts "#{WIKILYRICS_VERSION}"; exit }
		end

		begin

			parser.parse!( args )

			raise ArgumentError, I18n.get( "cli.error.missingoption", "--artist" ) if ! opts.artist && ! opts.batch_file
			raise ArgumentError, I18n.get( "cli.error.missingoption", "--title" ) if ! opts.title && ! opts.batch_file

			raise ArgumentError, I18n.get( "cli.error.missingoption", "--username" ) if opts.submit && ! opts.username
			raise ArgumentError, I18n.get( "cli.error.missingoption", "--password" ) if opts.submit && ! opts.password

			if opts.batch_file && (opts.artist || opts.title || opts.album || opts.year)
				raise ArgumentError, I18n.get( "cli.error.incompatibleoptions", "-b", "-a/-t/-l/-y" )
			end

			if opts.prompt_autogen && ( ! opts.submit || ! opts.review )
				raise ArgumentError, I18n.get( "cli.error.missingdependency", "-g", "-r" )
			end

			if opts.prompt_no_lyrics && ( ! opts.submit || ! opts.review )
				raise ArgumentError, I18n.get( "cli.error.missingdependency", "-n", "-r" )
			end

			opts.toolkits.each() do |toolkit|
				if ! TOOLKITS_DEFAULT.include?( toolkit )
					raise ArgumentError, I18n.get( "cli.error.invalidoptionvalue", "toolkit", toolkit )
				end
			end

 			if opts.submit && opts.review && opts.toolkits.empty?
				raise ArgumentError, I18n.get( "cli.error.notoolkit" )
			end

			if opts.submit
				if ! ["Lyriki","LyrikiLocal","LyricWiki"].include?( opts.submit )
					raise ArgumentError, I18n.get( "cli.error.invalidoptionvalue", "submit", opts.submit )
				end
				opts.sites = [] if ! opts.sites
				opts.sites << opts.submit
			end

			if ! opts.sites || opts.sites.empty?
				raise ArgumentError, I18n.get( "cli.error.nosite" )
			else
				found_plugins = Plugins.find_plugins()
				opts.sites.uniq!()
				opts.sites.each() do |site|
					if ! found_plugins.include?( site )
						raise ArgumentError, I18n.get( "cli.error.invalidoptionvalue", "site", site )
					end
				end
			end

			if opts.proxy
				begin
					# TODO is this correct?
					opts.proxy = nil if URI.parse( opts.proxy ).to_s() != ""
				rescue Exception
					raise ArgumentError, I18n.get( "cli.error.invalidoptionvalue", "proxy", opts.proxy )
				end
			end

			return opts

		rescue OptionParser::InvalidOption, OptionParser::AmbiguousOption, ArgumentError => ex
			puts ex.is_a?( ArgumentError ) ? "error: #{ex}" : ex
			puts parser
			exit 1
		end

	end

end
