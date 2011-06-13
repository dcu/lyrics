# encoding: utf-8
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
require "utils/http"
require "utils/xmlhash"
require "utils/formdata"
require "utils/strings"
require "utils/htmlentities"
require "i18n/i18n"
require "lyrics"

require "digest/md5"
require "cgi"

class MediaWikiLyrics < Lyrics

	class TrackData

		attr_reader :artist, :title, :year, :length, :genre

		def initialize( artist, title, length=nil, genre=nil )
			@artist = artist.strip().freeze()
			@title = title.strip().freeze()
			@length = 0
			if length
				tokens = length.to_s().split( ":" ).reverse()
				tokens.size.times() { |idx| @length += (60**idx) * tokens[idx].strip().to_i() }
			end
			@genre = genre ? genre.strip().freeze() : nil
		end

	end

	class AlbumData

		attr_reader :tracks, :artist, :title, :year, :month, :day, :length, :genres

		# NOTE: the artist is obtained from the tracks data. If it's not
		# the same for all tracks it would be varios_artists_name.
		def initialize( tracks, title, year, month=0, day=0, various_artists_name="(Various Artists)" )

			raise "tracks, title and year values can't be nil" if ! title || ! year || ! tracks
			raise "tracks value can't be empty" if tracks.empty?

			@tracks = tracks.clone().freeze()
			@title = title.strip().freeze()
			@year = year.kind_of?( String ) ? year.strip().to_i() : year.to_i()
			@month = month.kind_of?( String ) ? month.strip().to_i() : month.to_i()
			@day = day.kind_of?( String ) ? day.strip().to_i() : day.to_i()
			@various_artists_name = various_artists_name.strip().freeze()

			@artist = nil
			@genres = []
			genre = nil
			normalized_artist = nil
			@length = 0
			@tracks.each() do |track|
				if @artist == nil
					@artist = track.artist
					normalized_artist = Strings.normalize( @artist )
				elsif normalized_artist != Strings.normalize( track.artist )
					@artist = various_artists_name
				end
				if track.genre && ! @genres.include?( genre = String.capitalize( track.genre, true ) )
					@genres.insert( -1, genre )
				end
				@length += track.length
			end
			@genres.freeze()

		end

		def various_artists?()
			return @artist == @various_artists_name
		end

	end

	class SongData

		attr_reader :artist, :title, :lyrics, :album, :year, :credits, :lyricists

		def initialize( artist, title, lyrics, album=nil, year=nil, credits=nil, lyricists=nil )

			raise "artist and title values can't be nil" if ! artist || ! title

			@artist = artist.strip().freeze()
			@title = title.strip().freeze()
			@lyrics = lyrics ? lyrics.strip().freeze() : nil
			@album = album ? album.strip().freeze() : nil
			@year = year.kind_of?( String ) ? year.strip().to_i() : year.to_i()

			credits = credits.split( ";" ) if credits.is_a?( String )
			@credits = []
			credits.each() { |value| @credits << value.strip().freeze() } if credits.is_a?( Array )
			@credits.freeze()

			lyricists = lyricists.split( ";" ) if lyricists.is_a?( String )
			@lyricists = []
			lyricists.each() { |value| @lyricists << value.strip().freeze() } if lyricists.is_a?( Array )
			@lyricists.freeze()

		end

		def instrumental?()
			return @lyrics == nil
		end

	end


	@@NAME = "WL".freeze()
	@@VERSION = "0.13.4".freeze()
	@@AUTH_INTERVAL = 60*60 # check authorization every hour (it's only really checked if the user tries to submit something)
	@@REDIRECT_FOLLOWUPS = 3

	@@SEARCH_RESULT_TITLE = "title".freeze()
	@@SEARCH_RESULT_URL = "url".freeze()

	def MediaWikiLyrics.version()
		return @@VERSION
	end

	def version()
		return self.class.version()
	end

	attr_reader :username, :password

	def initialize( cleanup_lyrics=true, logger=nil, username=nil, password=nil )
		super( cleanup_lyrics, logger )
		@logged_in = false
		@cookie = nil
		@last_auth_check = 0 # last time we checked the control page
		@authorized = false
		@username = username ? username.clone().freeze() : nil
		@password = password ? password.clone().freeze() : nil
	end

	def control_page()
		return self.class.control_page()
	end

	def logged_in?()
		return @logged_in
	end

	def build_lyrics_fetch_data( request )
		return FetchPageData.new( build_song_rawdata_url( request.artist, request.title ) )
	end

	def page_error?( page_body )

		# database error
		db_error = /<!-- start content -->\s*(<p>|)A database query syntax error has occurred\.\s*This may indicate a bug in the software\.*/m.match( page_body )

		return true if db_error != nil

 		# page title error
		title_error = /<!-- start content -->\s*(<p>|)The requested page title was invalid, empty, or an incorrectly linked inter-language or inter-wiki title\. It may contain one( or|) more characters which cannot be used in titles\.*/m.match( page_body )

		return title_error != nil

	end
	protected :page_error?

	def MediaWikiLyrics.fetch_content_page( page_url, follow_redirects=@@REDIRECT_FOLLOWUPS )

		response, page_url = HTTP.fetch_page_get( page_url )
		page_url = page_url.sub( "&action=raw", "" )

		page_body = response ? response.body() : nil
		return nil, page_url if page_body == nil

		# work around redirects pages
		count = 0
		articles = [ parse_url( page_url ) ]
		while ( count < follow_redirects && (md = /#redirect ?('''|)\[\[([^\]]+)\]\]('''|)/i.match( page_body )) )

			article = cleanup_article( md[2] )
			if articles.include?( article ) # circular redirect found
				return nil, url
			else
				articles << article
			end

			response, page_url = HTTP.fetch_page_get( build_rawdata_url( article ) )
			page_url = page_url.sub( "&action=raw", "" )

			page_body = response ? response.body() : nil
			return nil, page_url if page_body == nil

			count += 1
		end

		page_body = "" if page_body.strip() == "/* Empty */"

		return page_body, page_url

	end

	def fetch_content_page( url, follow_redirects=@@REDIRECT_FOLLOWUPS )
		self.class.fetch_content_page( url, follow_redirects )
	end

	def fetch_lyrics_page( fetch_data )
		return nil, nil if fetch_data.url == nil
		log( "Fetching lyrics page... ", 0 )
		page_body, page_url = fetch_content_page( fetch_data.url )
		if page_body
			log( "OK" )
			log( response.body(), 2 ) if verbose_log?
		else
			log( "ERROR" )
		end
		return page_body, page_url
	end

	def lyrics_page_valid?( request, page_body, page_url )
		return ! page_error?( page_body )
	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_song_search_url( request.artist, request.title ) )
	end

	def lyrics_from_url( request, url )
		# we fetch and parse lyrics from raw content mode so we need the right url format
		if ! url.index( "&action=raw" )
			artist, title = parse_song_url( url )
			url = build_song_rawdata_url( artist, title, false )
		end
		return super( request, url )
	end

	def parse_suggestions( request, page_body, page_url )
		suggestions = []
		parse_search_results( page_body, true ).each() do |result|
			artist, title = parse_song_url( result[@@SEARCH_RESULT_URL] )
			if ! Strings.empty?( artist ) && ! Strings.empty?( title ) && /\ \([0-9]{4,4}\)$/.match( title ) == nil
				suggestions << Suggestion.new( artist, title, result[@@SEARCH_RESULT_URL] )
			end
		end
		return suggestions
	end

	def login( username=@username, password=@password, force=false )

		return true if ! force && @logged_in && username == @username && password == @password

		@username, @password = username, password
		notify = ! @logged_in || ! force

		if ! @username || ! @password
			notify( I18n.get( "wiki.login.error", @username ? @username : "<NONE>" ) ) if notify
			return @logged_in = false
		end

		notify( I18n.get( "wiki.login.attempt", @username ) ) if notify

		headers = { "Keep-Alive"=>"300", "Connection"=>"keep-alive" }
		resp, url = HTTP.fetch_page_get( "http://#{site_host()}/index.php?title=Special:Userlogin", headers )
		@cookie = resp.response["set-cookie"].split( "; " )[0]

		params = { "wpName"=>@username, "wpPassword"=>@password, "wpLoginattempt"=>"Log In" }
		headers.update( { "Cookie"=>@cookie } )
		resp, url = HTTP.fetch_page_post( "http://#{site_host()}/index.php?title=Special:Userlogin&action=submitlogin", params, headers, -1 )

		data = resp.body()
		data.gsub!( /[ \t\n]+/, " " )

		@logged_in = (/<h2>Login error:<\/h2>/.match( data ) == nil)
		@logged_in = (/<h1 class="firstHeading">Login successful<\/h1>/.match( data ) != nil) if @logged_in # recheck

		notify( I18n.get( "wiki.login." + (@logged_in ? "success" : "error"), @username ) ) if notify

		return @logged_in

	end

	def logout()
		@cookie = false
		if @logged_in
			@logged_in = false
			notify( I18n.get( "wiki.logout", @username ) )
		end
	end

	def authorized?()

		# debug( "AUTHORIZED INITIAL VALUE: #{@authorized}" )

		return @authorized if (Time.new().to_i() - @last_auth_check) < @@AUTH_INTERVAL

		body, url = fetch_content_page( build_rawdata_url( control_page() ) )
		return false if ! body

		# debug( "CONTROL PAGE:\n#{body}" )

		@last_auth_check = Time.new().to_i()

		control_data = {}
		body.split( "\n" ).each() do |line|
			if (md = /^([^=]+)=(.*)$/.match( line ))
				control_data[md[1].strip()] = md[2].strip()
			end
		end

		if control_data["BlockedVersions"].to_s().strip().split( /\s*;\s*/ ).include?( version() )
			notify( I18n.get( "wiki.control.versionblocked", version() ) )
			@authorized = false
			# debug( "VERSION BLOCKED" )
		elsif control_data["BlockedUsers"].to_s().strip().downcase().split( /\s*;\s*/ ).include?( @username.to_s().downcase() )
			notify( I18n.get( "wiki.control.userblocked", @username ) )
			@authorized = false
			# debug( "USER BLOCKED" )
		else

			if (last_version = control_data["LastVersion"].to_s().strip().split( "." )).size > 0
				curr_version = self.version().split( "." )
				curr_version.size.times() do |idx|
					if curr_version[idx].to_i() > last_version[idx].to_i()
						break
					elsif curr_version[idx].to_i() < last_version[idx].to_i()
						notify( I18n.get( "wiki.control.updated", control_data["LastVersion"] ) )
						break
					end
				end
			end

			@authorized = true
			# debug( "SUBMIT ALLOWED" )
		end

		return @authorized
	end

	def restore_session_params( username, password, cookie, last_auth_check=0, authorized=false )
		if ! Strings.empty?( cookie ) && ! Strings.empty?( username )
			@username = username
			@password = password
			@cookie = cookie
			@last_auth_check = last_auth_check.to_i()
			@authorized = authorized.to_s() == 'true'
			@logged_in = true
			notify( I18n.get( "wiki.session.restore.success", @username ) )
			return true
		else
			notify( I18n.get( "wiki.session.restore.error", @username ) )
			return false
		end

	end

	def restore_session( session_file )
		values = { "username" => nil, "password" => nil, "cookie" => nil, "last_auth_check" => nil, "authorized" => nil }
		if XMLHash.read( session_file, values )
			return restore_session_params(
				Strings.descramble( values["username"] ),
				Strings.descramble( values["password"] ),
				values["cookie"],
				values["last_auth_check"],
				values["authorized"]
			)
		else
			notify( I18n.get( "wiki.session.restore.notfound" ) )
			return false
		end
	end

	def get_session_params()
		return (@username ? @username.clone() : nil), (@password ? @password.clone() : nil), (@cookie ? @cookie.clone() : nil), @last_auth_check, @authorized
	end

	def save_session( session_file )
		if ! @logged_in
			notify( I18n.get( "wiki.session.save.error.notloggedin" ) )
			return false
		end
		values = {
			"username" =>			Strings.scramble( @username ),
			"password" =>			Strings.scramble( @password ),
			"cookie" =>				@cookie,
			"last_auth_check" =>	@last_auth_check,
			"authorized" =>			@authorized
		}
		if XMLHash.write( session_file, values )
			notify( I18n.get( "wiki.session.save.success", @username ) )
			return true
		else
			notify( I18n.get( "wiki.session.save.error", @username ) )
			return false
		end
	end


	def fetch_page_edit_params( page_url )
		headers = { "Keep-Alive"=>"300", "Connection"=>"keep-alive", "Referer"=>"#{page_url}", "Cookie"=>@cookie }
		response, page_url = HTTP.fetch_page_get( "#{page_url}&action=edit", headers )

		edit_params = {}
		return edit_params if ! response || response.code != "200"

		page_body = response.body()
		page_body.tr_s!( " \n\r\t", " " )

		if (md = /<input type=['"]hidden['"] value=['"]([a-fA-F0-9+\\]*)['"] name=['"]wpEditToken['"] ?\/>/.match( page_body ))
			edit_params["edit_token"] = md[1]
			if (md = /<input type=['"]hidden['"] value=['"]([0-9]+)['"] name=['"]wpEdittime['"] ?\/>/.match( page_body ))
				edit_params["edit_time"] = md[1]
			end
			if (md = /<input type=['"]hidden['"] value=['"]([0-9]+)['"] name=['"]wpStarttime['"] ?\/>/.match( page_body ))
				edit_params["start_time"] = md[1]
			end
			edit_params["logged_in"] = (/<li id="pt-logout">/.match( page_body ) != nil)
		end

		return edit_params
	end
	protected :fetch_page_edit_params

	def submit_page( page_url, page_content, summary="", watch=true, retries=1, auto_login=true )

		return false if (! logged_in? && ! auto_login) || ! authorized?

		(retries+1).times do

			begin

				next if ! logged_in? && ! login()

				# make sure we have the long url format
				page_url = build_url( parse_url( page_url ) )

				# Try to get the edit token for url, can't continue without it:
				edit_params = fetch_page_edit_params( page_url )

				if ! edit_params["logged_in"] # site says user is not logged in (session has expired), force relogin
					next if ! login( @username, @password, true )
					# after being successfully logged in, refetch the edit page
					edit_params = fetch_page_edit_params( page_url )
					next if ! edit_params["logged_in"]
				end

				next if ! edit_params["edit_token"]

				params = [
					MultipartFormData.text_param( "wpTextbox1", page_content ),
					MultipartFormData.text_param( "wpSummary", summary ),
					MultipartFormData.text_param( "wpWatchthis", watch ? "on" : "off" ),
					MultipartFormData.text_param( "wpSave", "Save page" ),
					MultipartFormData.text_param( "wpSection", "" ),
					MultipartFormData.text_param( "wpStarttime", edit_params["start_time"].to_s() ), # the new revision time
					MultipartFormData.text_param( "wpEdittime", edit_params["edit_time"].to_s() ), # the previous revision time
					MultipartFormData.text_param( "wpEditToken", edit_params["edit_token"] ),
				]

				headers = {
					"Keep-Alive"  => "300",
					"Connection"  => "keep-alive",
					"Referer"     => "http://#{site_host()}#{page_url}&action=edit",
					"Cookie"      => @cookie,
				}

				response, page_url = HTTP.fetch_page_post_form_multipart( "#{page_url}&action=submit", params, headers, -1 )

				return true if response.code == "302" # we should have received a redirect code

			rescue TimeoutError
			end
		end

		return false
	end

	def submit_redirect_page( page_url, link, summary=nil )
		if submit_page( page_url, "#REDIRECT #{link}", summary )
			notify( I18n.get( "wiki.submitredirect.success", link ) )
			return url
		else
			notify( I18n.get( "wiki.submitredirect.error", link ) )
			return nil
		end
	end

	def upload_file( src_file, dst_file, mime_type, description="", watch=true, auto_login=true )

		if ! logged_in?
			return false if ! auto_login || ! login()
		end

		begin
			data = File.new( src_file ).read()
		rescue Exception
			return false
		end

		params = [
			MultipartFormData.file_param( "wpUploadFile", File.basename( src_file ), mime_type, data ),
			MultipartFormData.text_param( "wpDestFile", dst_file ),
			MultipartFormData.text_param( "wpUploadDescription", description ),
			MultipartFormData.text_param( "wpWatchthis", watch ? "true" : "false" ),
			MultipartFormData.text_param( "wpUpload", "Upload file" ),
		]

		headers = {
			"Keep-Alive"  => "300",
			"Connection"  => "keep-alive",
			"Referer"     => "http://#{site_host()}/index.php?title=Special:Upload&wpDestFile=#{CGI.escape(dst_file)}",
			"Cookie"      => @cookie,
		}

		begin

			response, page_url = HTTP.fetch_page_post_form_multipart(
				"http://#{site_host()}/index.php?title=Special:Upload",
				params,
				headers,
				-1
			)

			# we have to receive a redirect code
			return true if response.code == "302"

			# error, possibly an expired session: relogin and try again
			login( @username, @password, true )
			response, page_url = HTTP.fetch_page_post_form_multipart(
				"http://#{site_host()}/index.php?title=Special:Upload",
				params,
				headers,
				-1
			)

			# again, we should have received a redirect
			return response.code == "302"

		rescue TimeoutError
			return false
		end

	end

	def upload_cover_image( image_path, artist, album, year, watch=true )

		album_art_name = build_album_art_name( artist, album, year )
		album_art_desc = build_album_art_description( artist, album, year )
		image_path, mime_type = prepare_image_file( image_path )

		if Strings.empty?( image_path ) || Strings.empty?( mime_type )
			notify( I18n.get( "wiki.uploadcover.error.convert" ) )
		else
			notify( I18n.get( "wiki.uploadcover.uploading", album, artist ) )
			if upload_file( image_path, album_art_name, mime_type, album_art_desc, watch )
				notify( I18n.get( "wiki.uploadcover.success", album, artist ) )
			else
				notify( I18n.get( "wiki.uploadcover.error", album, artist ) )
			end
		end

	end


	def build_tracks( album_data )
		return self.class.build_tracks( album_data )
	end

	def build_album_page( reviewed, artist, album, year, month, day, tracks, album_art )
		return self.class.build_album_page( reviewed, artist, album, year, month, day, tracks, album_art )
	end

	def submittable_album_params?( artist, album, year )
		if Strings.empty?( artist )
			notify( I18n.get( "wiki.submitalbum.error.invalidartist" ) )
			return false
		elsif Strings.empty?( album )
			notify( I18n.get( "wiki.submitalbum.error.invalidalbum" ) )
			return false
		elsif year <= 1900
			notify( I18n.get( "wiki.submitalbum.error.invalidyear" ) )
			return false
		else
			return true
		end
	end
	protected :submittable_album_params?

	# use skip_initial_page_search when you know the page doesn't exists (i.e. when you have already searched it)
	def submit_album_page( album_data, image_path=nil, allow_page_overwrite=true, skip_initial_page_search=false, show_review_dialog=true, must_review=false )

		show_review_dialog = true if must_review

		if ! allow_page_overwrite && ! skip_initial_page_search
			notify( I18n.get( "wiki.submitalbum.searchingpage", album_data.title, album_data.artist ) )
			if find_album_page_url( album_data.artist, album_data.title, album_data.year )
				notify( I18n.get( "wiki.submitalbum.pagefound", album_data.title, album_data.artist ) )
				return nil, nil
			else
				notify( I18n.get( "wiki.submitalbum.nopagefound", album_data.title, album_data.artist ) )
			end
		end

		page_data = {
			"site_name"		=> site_name(),
			"artist"		=> album_data.artist,
			"year" 			=> album_data.year,
			"month"			=> album_data.month,
			"day"			=> album_data.day,
			"album"			=> cleanup_title_token( album_data.title ),
			"tracks"		=> build_tracks( album_data ),
			"reviewed"		=> false
		}

		page_data["album_art_name"] = find_album_art_name( page_data["artist"], page_data["album"], page_data["year"] )
		if page_data["album_art_name"] == nil # album art not found, we'll attempt to upload it
			page_data["image_path"] = image_path.to_s()
			attempt_upload = true
		else
			attempt_upload = false
		end

	  # check if the album parameters are "submitteable" content
		return nil, nil if ! submittable_album_params?( page_data["artist"], page_data["album"], page_data["year"] )

		page_url = build_album_url( page_data["artist"], page_data["album"], page_data["year"], false )

		page_content = build_album_page(
			page_data["reviewed"],
			page_data["artist"],
			page_data["album"],
			page_data["year"],
			page_data["month"],
			page_data["day"],
			page_data["tracks"],
			page_data["album_art_name"] ?
				page_data["album_art_name"] :
				build_album_art_name( page_data["artist"], page_data["album"], page_data["year"] )
		)

		if attempt_upload && ! Strings.empty?( page_data["image_path"] )
			upload_cover_image( page_data["image_path"], page_data["artist"], page_data["album"], page_data["year"] )
		end

		summary = "#{page_data["reviewed"] ? "" : "autogen. "}album page (#{@@NAME}v#{@@VERSION})"
		if submit_page( page_url, page_content, summary )
			notify( I18n.get( "wiki.submitalbum.success", page_data["album"], page_data["artist"] ) )
			return page_url, page_data
		else
			notify( I18n.get( "wiki.submitalbum.error", page_url ) )
			return nil, page_data
		end

	end

	def build_song_page( reviewed, artist, title, album, year, credits, lyricist, lyrics )
		self.class.build_song_page( reviewed, artist, title, album, year, credits, lyricist, lyrics )
	end


	def submittable_song_params?( artist, song, lyrics, instrumental )
		if Strings.empty?( artist )
			notify( I18n.get( "wiki.submitsong.error.invalidartist" ) )
			return false
		elsif Strings.empty?( song )
			notify( I18n.get( "wiki.submitsong.error.invalidsong" ) )
			return false
		elsif Strings.empty?( lyrics ) && ! instrumental
			notify( I18n.get( "wiki.submitsong.error.nolyrics" ) )
			return false
		else
			return true
		end
	end
	protected :submittable_song_params?

	# if edit_url is not nil, it's assumed that we're trying to overwrite (edit) a page, otherwise
	# it's assummed that we're trying to create a new page and so overwritting won't be allowed
	# use skip_initial_page_search when you know the page doesn't exists (i.e. when you have already searched it)
	def submit_song_page( song_data, edit_url=nil, skip_initial_page_search=false, show_review_dialog=true, must_review=false )

		show_review_dialog = true if must_review

		if ! edit_url && ! skip_initial_page_search
			notify( I18n.get( "wiki.submitsong.searchingpage", song_data.title, song_data.artist ) )
			if find_song_page_url( song_data.artist, song_data.title )
				notify( I18n.get( "wiki.submitsong.pagefound", song_data.title, song_data.artist ) )
				return nil, nil
			else
				notify( I18n.get( "wiki.submitsong.nopagefound", song_data.title, song_data.artist ) )
			end
		end

		page_data = {
			"site_name"		=> site_name(),
			"edit_mode"		=> edit_url != nil,
			"artist"		=> cleanup_title_token( song_data.artist ),
			"year"			=> song_data.year,
			"album"			=> cleanup_title_token( song_data.album.to_s() ),
			"title"			=> cleanup_title_token( song_data.title ),
			"lyrics"		=> Strings.cleanup_lyrics( song_data.lyrics.to_s() ),
			"instrumental"	=> song_data.instrumental?,
			"credits"		=> song_data.credits.join( "; " ),
			"lyricist"		=> song_data.lyricists.join( "; " ),
			"reviewed"		=> false
		}

	  # check if the song parameters are "submitteable" content
		return nil, nil if ! submittable_song_params?( page_data["artist"], page_data["title"], page_data["lyrics"], page_data["instrumental"] )

		page_url = edit_url ? edit_url : build_song_url( page_data["artist"], page_data["title"], false )

		page_content = build_song_page(
			page_data["reviewed"],
			page_data["artist"],
			page_data["title"],
			page_data["album"],
			page_data["year"],
			page_data["credits"],
			page_data["lyricist"],
			page_data["lyrics"]
		)

		summary = "#{page_data["reviewed"] ? "" : "autogen. "}song page (#{@@NAME}v#{@@VERSION})"
		if submit_page( page_url, page_content, summary )
			notify( I18n.get( "wiki.submitsong.success", page_data["title"], page_data["artist"] ) )
			return page_url, page_data
		else
			notify( I18n.get( "wiki.submitsong.error", page_url ) )
			return nil, page_data
		end

	end

	def MediaWikiLyrics.parse_search_results( page_body, content_matches=false )

		results = []
		return results if page_body == nil

		page_body.tr_s!( " \n\r\t", " " )
		page_body.gsub!( /\ ?<\/?span[^>]*> ?/, "" )

		return results if ! page_body.sub!( /^.*<a name="(Article|Page)_title_matches">/, "" ) &&
						  ! page_body.sub!( /^.*<a name="No_(article|page)_title_matches">/, "" )

 		page_body.sub!( /<a name="No_(article|page)_text_matches">.*$/, "" ) if ! content_matches

		return results if ! page_body.gsub!( /<form id="powersearch" method="get" action="[^"]+">.*$/, "" )
		page_body.gsub!( /<\/[uo]l> ?<p( [^>]*|)>View \(previous .*$/, "" )

		page_body.split( "<li>" ).each() do |entry|
			if (md = /<a href="([^"]*index\.php\/|[^"]*index\.php\?title=|\/)([^"]*)" title="([^"]+)"/.match( entry ))
				result = {
					@@SEARCH_RESULT_URL => "http://#{site_host()}/index.php?title=#{md[2]}",
					@@SEARCH_RESULT_TITLE => md[3]
				}
				results << result if ! content_matches || ! results.include?( result )
			end
		end

		return results
	end

	def parse_search_results( page_body, content_matches=false )
		self.class.parse_search_results( page_body, content_matches )
	end

	@@FIND_TEMPLATE_START = 0
	@@FIND_TEMPLATE_NAME = 1
	@@FIND_TEMPLATE_PARAM = 2
	@@FIND_TEMPLATE_PARAM_VALUE = 3

	# NOTE: nested templates are only supported in named parameters values
	def MediaWikiLyrics.parse_template_rec( template_text, first_index )

		template_data = { "name" => "", "params" => {} }

		operation = @@FIND_TEMPLATE_START

		param_number = 1
		param_name = nil
		aux_index = -1

		link = false

		chr_index = first_index - 1
		chrs_array = template_text.is_a?( Array ) ? template_text : template_text.unpack( "U*" )
		max_chr_index = chrs_array.size-2

		while ( chr_index <= max_chr_index )

			chr_index += 1
			chr = [chrs_array[chr_index]].pack( "U" )

			if operation == @@FIND_TEMPLATE_START
				if chr == "{"
					aux_index = chr_index + 2 # start of template name
					operation = @@FIND_TEMPLATE_NAME
				end
			elsif operation == @@FIND_TEMPLATE_NAME
				if chr == "|"
					template_data["name"] = chrs_array[aux_index..chr_index-1].pack( "U*" ).strip()
					aux_index = chr_index + 1 # start of first parameter (if there is one)
					operation = @@FIND_TEMPLATE_PARAM
				elsif chr == "}" # we may have arrived to the template end (in which case the template has no parameters)
					next_chr = chrs_array[chr_index+1]
					if next_chr && [next_chr].pack( "U" ) == "}" # }} indicates the template end
						template_data["name"] = chrs_array[aux_index..chr_index-1].pack( "U*" ).strip()
						chr_index += 1
						break
					end
				end
			elsif operation == @@FIND_TEMPLATE_PARAM
				if chr == "="
					param_name = chrs_array[aux_index..chr_index-1].pack( "U*" ).strip()
					param_name = param_name.to_i() if param_name.to_i() > 0
					template_data["params"].delete( param_name )
					aux_index = chr_index + 1 # start of parameter value
					operation = @@FIND_TEMPLATE_PARAM_VALUE
				elsif link
					if chr == "]" # we may be at the end of a link (we no longer ignore | and } characters in that case)
						next_chr = chrs_array[chr_index+1]
						if next_chr && [next_chr].pack( "U" ) == "]" # ]] indicates the link end
							link = false
							chr_index += 1
						end
					end
				else
					if chr == "[" # we may be at the start of a link (we ignore the | and } characters in that case)
						next_chr = chrs_array[chr_index+1]
						if next_chr && [next_chr].pack( "U" ) == "[" # [[ indicates the link start
							link = true
							chr_index += 1
						end
					elsif chr == "|" # we arrived to the parameter end (the parameter has no name)
						template_data["params"][param_number] = chrs_array[aux_index..chr_index-1].pack( "U*" )
						HTMLEntities.decode!( template_data["params"][param_number] )
						param_number += 1
						aux_index = chr_index + 1 # start of next parameter (if there is one)
					elsif chr == "}" # we may have arrived to the template end (in which case the parameter has no name)
						next_chr = chrs_array[chr_index+1]
						if next_chr && [next_chr].pack( "U" ) == "}" # }} indicates the template end
							template_data["params"][param_number] = chrs_array[aux_index..chr_index-1].pack( "U*" )
							HTMLEntities.decode!( template_data["params"][param_number] )
							param_number += 1
							chr_index += 1
							break
						end
					end
				end
			elsif operation == @@FIND_TEMPLATE_PARAM_VALUE
				if chr == "{"	# we may have arrived at a nested template case (the only one
				 				# supported: template inserted in a named parameter value)
					next_chr = chrs_array[chr_index+1]
					if next_chr && [next_chr].pack( "U" ) == "{" # {{ indicates the template start
						template_data["params"][param_name] = [] if ! template_data["params"][param_name]
						param_array = template_data["params"][param_name]
						prev_text = chrs_array[aux_index..chr_index-1].pack( "U*" )
						HTMLEntities.decode!( prev_text )
						prev_text.lstrip!() if param_array.empty?
						param_array.insert( -1, prev_text ) if ! prev_text.empty?
						chr_index, nested_template_data = parse_template_rec( chrs_array, chr_index )
						param_array.insert( -1, nested_template_data )
						aux_index = chr_index + 1
					end
				elsif link
					if chr == "]" # we may be at the end of a link (we no longer ignore | and } characters in that case)
						next_chr = chrs_array[chr_index+1]
						if next_chr && [next_chr].pack( "U" ) == "]" # ]] indicates the link end
							link = false
							chr_index += 1
						end
					end
				else
					if chr == "[" # we may be at the start of a link (we ignore the | and } characters in that case)
						next_chr = chrs_array[chr_index+1]
						if next_chr && [next_chr].pack( "U" ) == "[" # [[ indicates the link start
							link = true
							chr_index += 1
						end
					elsif chr == "|" # we arrived to the parameter end
						last_text = chrs_array[aux_index..chr_index-1].pack( "U*" )
						HTMLEntities.decode!( last_text )
						if template_data["params"][param_name]
							param_array = template_data["params"][param_name]
							last_text.rstrip!()
							param_array.insert( -1, last_text ) if ! last_text.empty?
						else
							last_text.strip!()
							template_data["params"][param_name] = last_text
						end
						aux_index = chr_index + 1
						operation = @@FIND_TEMPLATE_PARAM
					elsif chr == "}" # we may have arrived to the template end
						next_chr = chrs_array[chr_index+1]
						if next_chr && [next_chr].pack( "U" ) == "}" # }} indicates the template end
							last_text = chrs_array[aux_index..chr_index-1].pack( "U*" )
							HTMLEntities.decode!( last_text )
							if template_data["params"][param_name]
								param_array = template_data["params"][param_name]
								last_text.rstrip!()
								param_array.insert( -1, last_text ) if ! last_text.empty?
							else
								last_text.strip!()
								template_data["params"][param_name] = last_text
							end
							chr_index += 1
							break
						end
					end
				end
			end

		end

		return chr_index, template_data

	end
	private_class_method :parse_template_rec

	def MediaWikiLyrics.parse_template( template_text )
		index, template_data = parse_template_rec( template_text, 0 )
		return template_data
	end

	def parse_template( template )
		return self.class.parse_template( template )
	end

	def MediaWikiLyrics.prepare_image_file( image_path, size_limit=153600 )
		4.times() do |trynumb|
			system( "convert", "-quality", (100-trynumb*10).to_s(), image_path, "/tmp/AlbumArt.jpg" )
			return nil, nil if $? != 0
			size = FileTest.size?( "/tmp/AlbumArt.jpg" )
			return "/tmp/AlbumArt.jpg", "image/jpeg" if (size ? size : 0) <= size_limit
		end
		return nil, nil
	end

	def prepare_image_file( image_path, size_limit=153600 )
		return self.class.prepare_image_file( image_path, size_limit )
	end



	def MediaWikiLyrics.cleanup_title_token( title, downcase=false )
		return cleanup_title_token!( String.new( title ), downcase )
	end

	def cleanup_title_token( title, downcase=false )
		return self.class.cleanup_title_token( title, downcase )
	end

	def cleanup_title_token!( title, downcase=false )
		return self.class.cleanup_title_token!( title, downcase )
	end

	def MediaWikiLyrics.get_sort_name( title )
		return get_sort_name!( String.new( title ) )
	end

	def get_sort_name( title )
		return self.class.get_sort_name( title )
	end

	def MediaWikiLyrics.get_sort_name!( title )

		title.gsub!( /\[[^\]\[]*\]/, "" )

		Strings.downcase!( title )

		title.gsub!( /[·\.,;:"`´¿\?¡!\(\)\[\]{}<>#\$\+\*%\^]/, "" )
		title.gsub!( /[\\\/_-]/, " " )
		title.gsub!( "&", "and" )
		title.squeeze!( " " )
		title.strip!()

		title.gsub!( /^a /, "" ) # NOTE: only valid for English
		title.gsub!( /^an /, "" )
		title.gsub!( /^the /, "" )
		title.gsub!( /^el /, "" )
		title.gsub!( /^le /, "" )
		title.gsub!( /^la /, "" )
		title.gsub!( /^l'([aeiou])/, "\\1" )
		title.gsub!( /^los /, "" )
		title.gsub!( /^las /, "" )
		title.gsub!( /^les /, "" )
		title.gsub!( "'", "" )

		Strings.remove_vocal_accents!( title )
		Strings.titlecase!( title, false, false )

		return title
	end

	def get_sort_name!( title )
		return self.class.get_sort_name!( title )
	end

	def MediaWikiLyrics.get_sort_letter( title )
		title = get_sort_name( title )
		title = title.strip()
		if title.index( /^[0-9]/ ) == 0
			return "0-9"
		else
			# return title.slice( 0, 1 )
			return title.unpack( "U*" ).slice( 0, 1 ).pack( "U*" )
		end
	end

	def get_sort_letter( title )
		return self.class.get_sort_letter( title )
	end



	# GENERAL FUNCTIONS

	def MediaWikiLyrics.cleanup_article( article, capitalize=true )
		article = article.gsub( "_", " " )
		article.strip!()
		article.squeeze!( " " )
		Strings.capitalize!( article, false, true ) if capitalize
		return article
	end

	def cleanup_article( article )
		return self.class.cleanup_article( article )
	end

	def MediaWikiLyrics.parse_link( link )

		if (md = /^ *\[\[([^\|\]]+)\]\] *$/.match( link ))
			article = cleanup_article( md[1] )
			return article, article if ! article.empty?
		end

		if (md = /^ *\[\[([^\|\]]+)\|([^\]]*)\]\] *$/.match( link ))
			article = cleanup_article( md[1] )
			if ! article.empty?
				display = cleanup_article( md[2], false )
				return article, display if ! display.empty?
			end
		end

		return nil, nil
	end

	def parse_link( link )
		return self.class.parse_link( link )
	end

	def MediaWikiLyrics.build_link( article, display=nil )
		return display ? "[[#{article}|#{display}]]" : "[[#{article}]]"
	end

	def build_link( article, display=nil )
		return self.class.build_link( article, display )
	end

	def MediaWikiLyrics.parse_url( url )
		if (md = /(https?:\/\/#{site_host()}\/|)(index.php\?title=|wiki\/|)([^&]+)(&.*|)$/.match( url ))
			return cleanup_article( CGI.unescape( md[3] ) ) # article title
		else
			return nil
		end
	end

	def parse_url( url )
		return self.class.parse_url( url )
	end

	def MediaWikiLyrics.build_url( article )
		# return "http://#{site_host()}/index.php?title=#{CGI.escape( article )}"
		return "http://#{site_host()}/index.php?title=#{CGI.escape( article.gsub( " ", "_" ) )}"
	end

	def build_url( article )
		return self.class.build_url( article )
	end

	def MediaWikiLyrics.build_rawdata_url( article )
		return build_url( article ) + "&action=raw"
	end

	def build_rawdata_url( article )
		return self.class.build_rawdata_url( article )
	end




	# SONG FUNCTIONS

	def MediaWikiLyrics.parse_song_link( link )
		article, display = parse_link( link )
		return nil, nil if article == nil
		if (md = /^([^:]+):(.+)$/.match( article ))
			return md[1], md[2]
		else
			return nil, nil
		end
	end

	def parse_song_link( link )
		return self.class.parse_song_link( link )
	end

	def MediaWikiLyrics.build_song_link( artist, title, cleanup=true )
		if cleanup
			artist = cleanup_title_token( artist )
			title = cleanup_title_token( title )
		end
		return build_link( "#{artist}:#{title}" )
	end

	def build_song_link( artist, title, cleanup=true )
		return self.class.build_song_link( artist, title, cleanup )
	end

	def MediaWikiLyrics.parse_song_url( url )
		article = parse_url( url )
		return nil, nil if article == nil
		if (md = /^([^:]+):(.+)$/.match( article ))
			return md[1], md[2] # artist, song title
		else
			return nil, nil
		end
	end

	def parse_song_url( url )
		return self.class.parse_song_url( url )
	end

	def MediaWikiLyrics.build_song_url( artist, title, cleanup=true )
		if cleanup
			artist = cleanup_title_token( artist )
			title = cleanup_title_token( title )
		end
		return build_url( "#{artist}:#{title}" )
	end

	def build_song_url( artist, title, cleanup=true )
		return self.class.build_song_url( artist, title, cleanup )
	end

	def MediaWikiLyrics.build_song_rawdata_url( artist, title, cleanup=true )
		return build_song_url( artist, title, cleanup ) + "&action=raw"
	end

	def build_song_rawdata_url( artist, title, cleanup=true )
		return self.class.build_song_rawdata_url( artist, title, cleanup )
	end

	def MediaWikiLyrics.build_song_edit_url( artist, title, cleanup=true )
		return build_song_url( artist, title, cleanup ) + "&action=edit"
	end

	def build_song_edit_url( artist, title, cleanup=true )
		return self.class.build_song_edit_url( artist, title, cleanup )
	end

	def MediaWikiLyrics.build_song_add_url( request, cleanup=true )
		return build_song_url( request.artist, request.title, cleanup ) + "&action=edit"
	end

	def build_song_add_url( request, cleanup=true )
		return self.class.build_song_add_url( request, cleanup )
	end

	def MediaWikiLyrics.build_song_search_url( artist, title )
		artist = cleanup_title_token( artist )
		title = cleanup_title_token( title )
		search_string = CGI.escape( "#{artist}:#{title}" )
		return "http://#{site_host()}/index.php?redirs=1&search=#{search_string}&fulltext=Search&limit=500"
	end

	def build_song_search_url( artist, title )
		return self.class.build_song_search_url( artist, title )
	end

	def MediaWikiLyrics.find_song_page_url( artist, title )

		url = build_song_rawdata_url( artist, title )
		body, url = fetch_content_page( url )

		if ! Strings.empty?( body ) # page exists
			return url
		else
			artist = Strings.normalize( cleanup_title_token( artist ) )
			title = Strings.normalize( cleanup_title_token( title ) )
			normalized_target = "#{artist}:#{title}"

			response, url = HTTP.fetch_page_get( build_song_search_url( artist, title ) )
			return nil if response == nil
			parse_search_results( response.body(), true ).each() do |result|
				normalized_result = result[@@SEARCH_RESULT_TITLE].split( ":" ).each() do |token|
					Strings.normalize!( token )
				end.join( ":" )
				return result[@@SEARCH_RESULT_URL] if normalized_target == normalized_result
			end

			return nil
		end

	end

	def find_song_page_url( artist, title )
		return self.class.find_song_page_url( artist, title )
	end



	# ALBUM FUNCTIONS

	def MediaWikiLyrics.parse_album_link( link )
		article, display = parse_link( link )
		return nil, nil, nil if article == nil
		if (md = /^([^:]+):(.+) \(([0-9]{4,4})\)$/.match( article ))
			return md[1], md[2], md[3]
		else
			return nil, nil, nil
		end
	end

	def parse_album_link( link )
		return self.class.parse_album_link( link )
	end

	def MediaWikiLyrics.build_album_link( artist, album, year, cleanup=true )
		if cleanup
			artist = cleanup_title_token( artist )
			album = cleanup_title_token( album )
		end
		return build_link( "#{artist}:#{album} (#{year})" )
	end

	def build_album_link( artist, album, year, cleanup=true )
		return self.class.build_album_link( artist, album, year, cleanup )
	end

	def MediaWikiLyrics.parse_album_url( url )
		article = parse_url( url )
		return nil, nil, nil if article == nil
		if (md = /^([^:]+):(.+) \(([0-9]{4,4})\)$/.match( article ))
			return md[1], md[2], md[3]
		else
			return nil, nil, nil
		end
	end

	def parse_album_url( url )
		return self.class.parse_album_url( url )
	end

	def MediaWikiLyrics.build_album_url( artist, album, year, cleanup=true )
		if cleanup
			artist = cleanup_title_token( artist )
			album = cleanup_title_token( album )
		end
		return build_url( "#{artist}:#{album} (#{year})" )
	end

	def build_album_url( artist, album, year, cleanup=true )
		return self.class.build_album_url( artist, album, year, cleanup )
	end

	def MediaWikiLyrics.build_album_rawdata_url( artist, album, year, cleanup=true )
		return build_album_url( artist, album, year, cleanup ) + "&action=raw"
	end

	def build_album_rawdata_url( artist, album, year, cleanup=true )
		return self.class.build_album_rawdata_url( artist, album, year, cleanup )
	end

	def MediaWikiLyrics.build_album_edit_url( artist, album, year, cleanup=true )
		return build_album_url( artist, album, year, cleanup ) + "&action=edit"
	end

	def build_album_edit_url( artist, album, year, cleanup=true )
		return self.class.build_album_edit_url( artist, album, year, cleanup )
	end

	def MediaWikiLyrics.build_album_search_url( artist, album, year )
		artist = cleanup_title_token( artist )
		album = cleanup_title_token( album )
		search_string = CGI.escape( "#{artist}:#{album} (#{year})" )
		return "http://#{site_host()}/index.php?redirs=1&search=#{search_string}&fulltext=Search&limit=500"
	end

	def build_album_search_url( artist, album, year )
		return self.class.build_album_search_url( artist, album, year )
	end

	def MediaWikiLyrics.find_album_page_url( artist, album, year )

		url = build_album_rawdata_url( artist, album, year )
		body, url = fetch_content_page( url )

		if ! Strings.empty?( body ) # page exists
			return url
		else
			artist = Strings.normalize( cleanup_title_token( artist ) )
			album = Strings.normalize( cleanup_title_token( album ) )
			normalized_target = "#{artist}:#{album} #{year}" # NOTE: normalize removes the parenthesis

			response, url = HTTP.fetch_page_get( build_album_search_url( artist, album, year ) )
			return nil if response == nil || response.body() == nil
			parse_search_results( response.body(), true ).each() do |result|
				normalized_result = result[@@SEARCH_RESULT_TITLE].split( ":" ).each() do |token|
					Strings.normalize!( token )
				end.join( ":" )
				return result[@@SEARCH_RESULT_URL] if normalized_target == normalized_result
			end
			return nil
		end

	end

	def find_album_page_url( artist, album, year )
		return self.class.find_album_page_url( artist, album, year )
	end


	# ALBUM ART FUNCTIONS

	def build_album_art_name( artist, album, year, extension="jpg", cleanup=true )
		return self.class.build_album_art_name( artist, album, year, extension, cleanup )
	end

	def build_album_art_description( artist, album, year, cleanup=true )
		return self.class.build_album_art_description( artist, album, year, cleanup )
	end

	def find_album_art_name( artist, album, year )
		return self.class.find_album_art_name( artist, album, year )
	end

	def MediaWikiLyrics.find_album_art_url( artist, album, year )
		if album_art_name = find_album_art_name( artist, album, year )
			album_art_name.gsub!( " ", "_" )
			return "http://#{site_host()}/index.php?title=Image:#{CGI.escape(album_art_name)}"
		else
			return nil
		end
	end

	def find_album_art_url( artist, album, year )
		return self.class.find_album_art_url( artist, album, year )
	end


	# DATE FUNCTIONS

	@@months = [
		"JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY",
		"AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
	]

	def MediaWikiLyrics.parse_date( date )

		day, month, year = nil, nil, nil

		if (md = /^(#{@@months.join( "|" )})( \d\d?|), (\d\d\d\d)$/i.match( date ))
			month, day, year = @@months.index( Strings.upcase( md[1] ) ) + 1, md[2].strip().to_i(), md[3].to_i()
		elsif (md = /^(\d\d? |)(#{@@months.join( "|" )}) (\d\d\d\d)$/i.match( date ))
			day, month, year = md[1].strip().to_i(), @@months.index( Strings.upcase( md[2] ) ) + 1, md[3].to_i()
		elsif /^(\d\d\d\d)-(\d\d)-(\d\d)$/.match( date )
			year, month, day = md[1].to_i(), md[2].to_i(), md[3].to_i()
		elsif (md = /^(\d\d\d\d)$/.match( date ))
			year = md[1].to_i()
		end

		year = nil if year == 0
		month = nil if month == 0
		day = nil if day == 0

		return year, month, day

	end

	def MediaWikiLyrics.build_date( year, month, day )

		year, month, day = year.to_i(), month.to_i(), day.to_i()

		if month != 0
			month = @@months[month-1].to_s()
			month = month.slice( 0..0 ).upcase() + month.slice( 1..-1 ).downcase()
		end

		if day != 0 && month != 0 && year != 0
			return "#{month} #{day}, #{year}"
		elsif month != 0 && year != 0
			return "#{month}, #{year}"
		elsif year != 0
			return year.to_s()
		else
			return ""
		end

	end

end
