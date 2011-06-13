# encoding: utf-8
# Copyright (C) 2007 by Sergio Pistone
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

require "utils/strings"
require "utils/htmlentities"
require "utils/http"
require "lyrics"

class LoudSongs < Lyrics

	def LoudSongs.site_host()
		return "www.loudson.gs"
	end

	def LoudSongs.site_name()
		return "LoudSongs"
	end

	def LoudSongs.lyrics_test_data()
		return [
			Request.new( "Radiohead", "Optimistic", "Kid A" ),
			Request.new( "Nirvana", "About a Girl", "Bleach" ),
			Request.new( "Placebo", "Taste in Men", "Black Market Music" ),
			Request.new( "A Perfect Circle", "The Noose", "Thirteen Step" ),
		]
	end

	def LoudSongs.build_song_add_url( request )
		return "http://#{site_host()}/add"
	end

	def LoudSongs.build_google_feeling_lucky_url( artist, title=nil )
		query = Strings.google_search_quote( title ? artist : artist + " lyrics" )
		query << " " << Strings.google_search_quote( title + " lyrics" ) if title
		return Strings.build_google_feeling_lucky_url( query, site_host() )
	end

	def build_lyrics_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist, request.title ) )
	end

	def lyrics_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) - [^<]+ - ([^<]+) lyrics<\/title>/i.match( page_body )
		return false if ! md
		return	Strings.normalize( md[1] ) == Strings.normalize( request.artist ) &&
				Strings.normalize( md[2] ) == Strings.normalize( request.title )
	end

	def parse_lyrics( response, page_body )

		page_body.tr_s!( " \n\r\t", " " )

		if (md = /<h1>Lyrics for: ([^<]+) - ([^<]+)<\/h1> <h1>([0-9])+\) ([^<]+)<\/h1>/.match( page_body ))
			response.artist = Strings.titlecase( md[1].strip() )
			response.album = Strings.titlecase( md[2].strip() )
			response.title = Strings.titlecase( md[4].strip() )
			response.custom_data = { "track" => md[3] }
		end

		if (md = /<em>Release Year:<\/em> ?([0-9]{4}) ?<br \/>/.match( page_body ))
			response.year = md[1]
		end

		return if ! page_body.gsub!( /^.*<div class="middle_col_TracksLyrics ?">/i, "" )
		return if ! page_body.gsub!( /<\/div>.*$/i, "" )

		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )

		response.lyrics = page_body

	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist ) )
	end

	def suggestions_page_valid?( request, page_body, page_url )
		return page_url.index( "http://#{site_host()}/" ) == 0 # TODO
	end

	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		if page_url.count( "/" ) == 4 # ARTIST PAGE

			return suggestions if ! page_body.sub!( /^.*<ul>/i, "" )
			return suggestions if ! page_body.sub!( /<\/ul>.*$/i, "" )

			page_body.split( /<\/li> ?<li>/ ).each() do |album_entry|
				if (md = /<a href="([^"]+)">/.match( album_entry ))
					suggestions << FetchPageData.new( md[1].downcase() )
				end
			end

		else # page_url.count( "/" ) == 3 # ALBUM PAGE

			return suggestions if ! page_body.sub!( /^.*<ul>/i, "" )
			return suggestions if ! page_body.sub!( /<\/ul>.*$/i, "" )

			HTMLEntities.decode!( page_body )

			page_body.split( /<\/li> ?<li>/ ).each() do |song_entry|
				if (md = /<a href="([^"]+)">[0-9]+. ([^<]+)<\/a>/.match( song_entry ))
					suggestions << Suggestion.new( request.artist, md[2], md[1].downcase() )
				end
			end

		end

		return suggestions

	end

end
