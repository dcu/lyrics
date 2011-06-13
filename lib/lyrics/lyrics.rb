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

$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "utils/logger"
require "utils/strings"
require "utils/http"

$VERBOSE_LOG = false

def debug( message )
	system( "kdialog", "--msgbox", "<qt>" + message.to_s().gsub( "\n", "<br />" ) + "</qt>" )
end

class Lyrics

	class Request

		attr_reader :artist, :title, :album, :year, :fetch_data
		attr_writer :fetch_data

		def initialize( artist, title, album=nil, year=nil )
			raise "target artist and title values can't be nil" if ! artist || ! title
			@artist = artist.clone().freeze()
			@title = title.clone().freeze()
			@album = album ? album.clone().freeze() : nil
			@year = year ? year.to_s().strip().to_i() : nil
			@fetch_data = nil
		end

		def to_s()
			ret = " - request artist: #{@artist}\n - request title: #{@title}"
			ret << "\n - request album: #{@album}" if @album
			ret << "\n - request year: #{@year}" if @year
			return ret
		end

	end

	class Response

		attr_reader :request, :artist, :title, :album, :year, :lyrics, :url, :custom_data #, :suggestions
		attr_writer :url

		def initialize( request )
			raise "request can't be nil" if ! request
			@request = request
			@artist = nil
			@title = nil
			@album = nil
			@year = nil
			@lyrics = nil
			@custom_data = {}
		end

		def to_s()
			ret = ""
			ret << "\n - response artist: #{@artist}" if @artist
			ret << "\n - response title: #{@title}" if @title
			ret << "\n - response album: #{@album}" if @album
			ret << "\n - response year: #{@year}" if @year
			if @custom_data.size > 0
				ret << "\n - response custom data:"
				@custom_data.each { |key, val| ret << "\n    - #{key}: #{val}" }
			end
			return ret.size > 0 ? ret.slice( 1..-1 ) : ret
		end

		def each_modified!()
			yield "artist", @artist if artist_modified?()
			yield "title", @title if title_modified?()
			yield "album", @album if album_modified?()
			yield "year", @year if year_modified?()
		end

		def each_modified()
			each_modified!() { |k, v| yield k, v.clone() }
		end

		def artist_modified?()
			return @artist && @artist != request.artist
		end

		def artist=( artist )
			@artist = artist ? artist.to_s().strip().freeze() : nil
		end

		def title_modified?()
			return @title && @title != request.title
		end

		def title=( title )
			@title = title ? title.to_s().strip().freeze() : nil
		end

		def album_modified?()
			return @album && @album != request.album
		end

		def album=( album )
			@album = album ? album.to_s().strip().freeze() : nil
		end

		def year_modified?()
			return @year && @year != request.year
		end

		def year=( year )
			if year
				year = year.to_s().strip().to_i()
				if year > 1900
					@year = year
				else
					@year = nil
				end
			else
				@year = nil
			end
		end

		def lyrics=( lyrics )
			@lyrics = Strings.decode_htmlentities!( lyrics.to_s() ).strip().freeze()
			@lyrics = nil if @lyrics.empty?
		end

		def custom_data=( custom_data )
			raise "custom_data value must be a hash" if ! custom_data.is_a?( Hash )
			@custom_data = {}
			custom_data.each() { |k, v| @custom_data[k] = v.is_a?( String ) ? v.clone().freeze() : v }
			@custom_data.freeze()
		end

	end

	class Suggestion

		attr_reader :url, :artist, :title

		def initialize( artist, title, url )
			@artist = artist.clone().freeze()
			@title = title.clone().freeze()
			@url = url.clone.freeze()
		end

		def to_s()
			return "art: #{artist} | tit: #{title} | url: #{url}"
		end

	end

	class FetchPageData

		attr_reader :url, :post_data, :headers_data

		def initialize( url, post_data=nil, headers_data=nil )
			@url = url.freeze()
			if post_data && post_data.size > 0
				@post_data = post_data.clone().freeze()
				@post_data.each() do |key|
					@post_data[key] = @post_data[key].clone().freeze() if @post_data[key]
				end
			else
				@post_data = nil
			end
			if headers_data && headers_data.size > 0
				@headers_data = headers_data.clone().freeze()
				@headers_data.each() do |key|
					@headers_data[key] = @headers_data[key].clone().freeze() if @headers_data[key]
				end
			else
				@headers_data = nil
			end
		end

		def to_s()
			ret = " - fetch url: #{@url}"
			if @post_data
				ret << "\n - fetch post data:"
				@post_data.each { |key, val| ret << "\n    - #{key}: #{val}" }
			end
			if @headers_data
				ret << "\n - fetch headers data:"
				@headers_data.each { |key, val| ret << "\n    - #{key}: #{val}" }
			end
			return ret
		end

	end

	attr_reader :cleanup_lyrics
	attr_writer :cleanup_lyrics

	def initialize( cleanup_lyrics=true, logger=nil )
		super()
		@cleanup_lyrics = cleanup_lyrics
		@logger = logger
		@tabulation = nil
		@skip_tabulation = false
	end

	def log?()
		return @logger != nil
	end

	def verbose_log?()
		return log? && $VERBOSE_LOG
	end

	def logger=( logger )
		@logger = logger
	end

	def log( message, new_lines=1 )
		@logger.log( message, new_lines ) if @logger
	end

	def increase_tabulation_level()
		@logger.increase_tabulation_level() if @logger
	end

	def decrease_tabulation_level()
		@logger.decrease_tabulation_level() if @logger
	end

	def site_host()
		return self.class.site_host()
	end

	def site_name()
		return self.class.site_name()
	end

	def Lyrics.build_song_add_url( request )
		return nil
	end

	def build_song_add_url( request )
		return self.class.build_song_add_url( request )
	end

	def Lyrics.known_url?( url )
		return url.index( "http://#{site_host}" ) == 0
	end

	def known_url?( url )
		return self.class.known_url?( url )
	end

	def notify( message )
		puts "#{site_name()}: #{message}"
	end

	# Returns a FetchPageData instance
	def build_lyrics_fetch_data( request )
		return FetchPageData.new( nil )
	end

	# Returns the lyrics page body (or nil if it couldn't be retrieved) and the corresponding url (or nil)
	def fetch_lyrics_page( fetch_data )

		return nil, nil if ! fetch_data.url

		log( "Fetching lyrics page... ", 0 )
		if fetch_data.post_data
			response, url = HTTP.fetch_page_post( fetch_data.url, fetch_data.post_data, fetch_data.headers_data )
		else
			response, url = HTTP.fetch_page_get( fetch_data.url, fetch_data.headers_data )
		end

		if response && response.body()
			log( "OK" )
			log( response.body(), 2 ) if verbose_log?
			return response.body(), url
		else
			log( "ERROR" )
			return nil, url
		end

	end

	# NOTE: override for example if your using google feeling lucky to verify that
	# the resulting page is not just some random (trashy) result.
	# Returns false is page_body does not correspond to the requested lyrics
	def lyrics_page_valid?( request, page_body, page_url )
		return true
	end

	# NOTE: implement in subclasses
	# Must fill the relevante response properties (lyrics, [artist, title, album, year, custom_data])
	# def parse_lyrics( response, page_body )
	# end

	# Returns a Lyrics::Response object
	def lyrics_direct_search( request )

		fetch_data = build_lyrics_fetch_data( request )

		log(
			site_name().upcase() + "\n" +
			"Attempting LYRICS DIRECT SEARCH...\n" +
			request.to_s() + "\n" +
			fetch_data.to_s()
		)

		page_body, page_url = fetch_lyrics_page( fetch_data )

		response = Response.new( request )

		if page_body
			if lyrics_page_valid?( request, page_body, page_url )
				log( "Parsing lyrics... ", 0 )
				response.url = page_url
				parse_lyrics( response, page_body )
				log( response.lyrics ? "LYRICS FOUND" : "LYRICS NOT FOUND" )
				log( response.to_s() )
				log( " - parsed lyrics:\n[#{lyrics_data.lyrics}" ) if verbose_log?
				response.lyrics = Strings.cleanup_lyrics( response.lyrics ) if response.lyrics && @cleanup_lyrics
			else
				log( "LYRICS PAGE IS INVALID" )
			end
		end

		return response

	end

	# Returns a Lyrics::Response object
	def lyrics_from_url( request, url )

		response = Response.new( request )

		if ! known_url?( url )
			log( site_name().upcase() + "\nCan't handle received URL: " + url )
			return response
		end

		fetch_data = build_lyrics_fetch_data( request )
		fetch_data = FetchPageData.new( url, fetch_data.post_data, fetch_data.headers_data )

		log(
			site_name().upcase() + "\n" +
			"Retrieving LYRICS FROM URL...\n" +
			request.to_s() + "\n" +
			fetch_data.to_s()
		)

		page_body, url = fetch_lyrics_page( fetch_data )

		if page_body
			log( "Parsing lyrics... ", 0 )
			response.url = url
			parse_lyrics( response, page_body )
			log( response.lyrics ? "LYRICS FOUND" : "LYRICS NOT FOUND" )
			log( response.to_s() )
			log( " - parsed lyrics:\n[#{lyrics_data.lyrics}]" ) if verbose_log?
			response.lyrics = Strings.cleanup_lyrics( response.lyrics ) if response.lyrics && @cleanup_lyrics
		end

		return response

	end

	# Returns a FetchPageData instance
	def build_suggestions_fetch_data( request )
		return FetchPageData.new( nil )
	end

	# Returns the lyrics page body (nil if it couldn't be retrieved) and the response url
	def fetch_suggestions_page( fetch_data )

		return nil, nil if ! fetch_data.url

		log( fetch_data.to_s() + "\nFetching suggestions page... ", 0 )

		if fetch_data.post_data
			response, url = HTTP.fetch_page_post( fetch_data.url, fetch_data.post_data, fetch_data.headers_data )
		else
			response, url = HTTP.fetch_page_get( fetch_data.url, fetch_data.headers_data )
		end

		if response && response.body()
			log( "OK" )
			log( response.body(), 2 ) if verbose_log?
			return response.body(), url
		else
			log( "ERROR" )
			return nil, url
		end

	end

	# NOTE: override for example if your using google feeling lucky to verify that
	# the resulting page is not just some random (trashy) result.
	# Returns false is body does not correspond to the required suggestions page
	def suggestions_page_valid?( request, page_body, page_url )
		return true
	end

	# NOTE: implement in subclasses
	# Returns an array of Suggestion objects
	# def parse_suggestions( request, page_body, page_url )
	# 	return []
	# end

	# Returns an array of maps { url, artist, title }
	def suggestions( request )

		log( site_name().upcase() + "\nRetrieving SUGGESTIONS...\n" + request.to_s() )

		fetch_data = build_suggestions_fetch_data( request )
		suggestions = []

		suggestions_rec( request, fetch_data, suggestions, 0 )

		return suggestions

	end

	def suggestions_rec( request, fetch_data, cumulative_suggestions, recursion_level )

		page_body, page_url = fetch_suggestions_page( fetch_data )
		return if page_body == nil

		if suggestions_page_valid?( request, page_body, page_url )

			log( "Parsing suggestions...", 0 )
			suggestions = parse_suggestions( request, page_body, page_url )

			if ! suggestions.is_a?( Array )
				log( " INVALID RESPONSE FROM PARSE_SUGGESTIONS" )
				return
			end

			if suggestions.empty?
				log( " NO SUGGESTIONS FOUND" )
				return
			else
				log( "" )
			end

			suggestions.each() do |suggestion|
				if suggestion.is_a?( FetchPageData )
					log( " - url: #{suggestion.url}" )
					increase_tabulation_level()
					log( "Retrieving SUGGESTIONS LEVEL#{recursion_level+2}..." )
					suggestions_rec( request, suggestion, cumulative_suggestions, recursion_level + 1 )
					decrease_tabulation_level()
				else
					log( " - #{suggestion.to_s()}" )
					cumulative_suggestions << suggestion
				end
			end

		else
			log( "SUGGESTIONS PAGE IS INVALID" )
		end

	end
	protected :suggestions_rec


	def lyrics_from_suggestions( request, suggestions=nil )

		log( site_name().upcase() + "\nSearching LYRICS FROM SUGGESTIONS..." )

		suggestions = suggestions( request ) if suggestions == nil

		normalized_artist, normalized_title = Strings.normalize( request.artist ), Strings.normalize( request.title )

		log( "Scanning suggestions... ", 0 )
		suggestions.each() do |suggestion|
			next if ! suggestion.is_a?( Suggestion )
			if Strings.normalize( suggestion.artist ) == normalized_artist &&
			   Strings.normalize( suggestion.title ) == normalized_title
				log( "MATCH FOUND\n" + suggestion.to_s() )
				# TODO should we use request.album and request.year here?
				response = lyrics_from_url(
					Request.new( suggestion.artist, suggestion.title, request.album, request.year ),
					suggestion.url
				)
				return response, suggestions if response.lyrics
			end
		end

		log( "NO VALID MATCH FOUND" )

		return Response.new( request ), suggestions

	end

	# Returns a Lyrics::Response object
	def lyrics_full_search( request )

		# LYRICS DIRECT SEARCH:
		response = lyrics_direct_search( request )
		return response if response.lyrics

		# NOT FOUND, SEARCH IN SUGGESTIONS:
		response, suggs = lyrics_from_suggestions( request, suggestions( request ) )
		return response
	end

	# default implementation, overide if there is a more accurate expression for a specific site
	def Lyrics.build_google_feeling_lucky_url( artist, title=nil )
		query = Strings.google_search_quote( artist )
		query << " " << Strings.google_search_quote( title ) if title
		query << " lyrics"
		return Strings.build_google_feeling_lucky_url( query, self.site_host() )
	end

	def build_google_feeling_lucky_url( artist, title=nil )
		return self.class.build_google_feeling_lucky_url( artist, title )
	end

	# NOTE: if possible use popular song that are likely to be indexed by google.
	# We are not testing here how good or complete a site is but if the site plugin
	# is behaving as expected. We part from the assumption that every plugin should
	# be able to get lyrics and suggestions for the values returned here.
	def Lyrics.lyrics_test_data()
		return [
			Request.new( "Nirvana", "Smells Like Teen Spirit", "Nevermind" ),
			Request.new( "Radiohead", "Optimistic", "Kid A" ),
			Request.new( "Massive Attack", "Protection", "Protection" ),
			Request.new( "Pearl Jam", "Porch", "Ten" ),
# 			Request.new( "The Cranberries", "Linger", "Everybody Else Is Doing It, So Why Can't We?" ),
# 			Request.new( "Radiohead", "Idioteque", "Kid A" ),
# 			Request.new( "Radiohead", "How To Disappear Completely","stitle"=>"How To Dissapear", "Kid A" ),
# 			Request.new( "Pearl Jam", "Love Boat Captain", "Riot Act" ),
# 			Request.new( "Blur", "No Distance Left To Run", "13" ),
# 			Request.new( "Opeth", "Hope Leaves", "Damnation" ),
# 			Request.new( "Megadeth", "À tout le monde", "Youthanasia" ),
# 			Request.new( "Metallica", "Master of Puppets", "Master of Puppets" ),
# 			Request.new( "Lacuna Coil", "Heaven's a Lie", "Comalies" ),
# 			Request.new( "Pearl Jam", "Porch", "Ten" ),
# 			Request.new( "Portishead", "Wandering Star", "Dummy" ),
		]
	end

	def lyrics_test_data()
		return self.class.lyrics_test_data()
	end

	def Lyrics.suggestions_test_data()
		return lyrics_test_data()
	end

	def suggestions_test_data()
		return self.class.suggestions_test_data()
	end

end
