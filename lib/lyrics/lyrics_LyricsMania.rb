# encoding: utf-8
# Copyright (C) 2007-2008 by
# Davide Lo Re <boyska@gmail.com>
# Sergio Pistone <sergio_pistone@yahoo.com.ar>
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
require "lyrics"

require "cgi"

class LyricsMania < Lyrics

	def LyricsMania.site_host()
		return "www.lyricsmania.com"
	end

	def LyricsMania.site_name()
		return "LyricsMania"
	end

	def LyricsMania.lyrics_test_data()
		return [
			Request.new( "Nirvana", "Lounge Act", "Nevermind" ),
			Request.new( "Radiohead", "Idioteque", "Kid A" ),
			Request.new( "Pearl Jam", "Porch", "Ten" ),
			Request.new( "The Smashing Pumpkins", "Mayonaise", "Siamese Dream" ),
		]
	end

	def LyricsMania.build_song_add_url( request )
		return "http://#{site_host()}/add.html"
	end

	def LyricsMania.build_google_feeling_lucky_url( artist, title=nil )
		query =  Strings.google_search_quote( artist )
		query << " " << Strings.google_search_quote( title + " lyrics" ) if title
		return Strings.build_google_feeling_lucky_url( query, site_host() )
	end

	def build_lyrics_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist, request.title ) )
	end

	def lyrics_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) Lyrics<\/title>/i.match( page_body )
		return false if ! md
		page_title = Strings.normalize( md[1] )
		return	page_title.index( Strings.normalize( request.artist ) ) &&
				page_title.index( Strings.normalize( request.title ) )
	end

	def parse_lyrics( response, page_body )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		return if ! page_body.sub!( /^.* lyrics<\/h3>/, "" ) # metadata

		metadata = {}
		["artist", "album"].each() do |key|
			if (md =/#{key}: <b><a href=[^>]+>([^<]+)<\/a><\/b>/i.match( page_body ))
				metadata[key.downcase()] = md[1].strip().sub( /\ *lyrics$/, "" )
			end
		end
		["year", "title"].each() do |key|
			if (md =/#{key}: ([^<]+)<(br|\/td)>/i.match( page_body ))
				metadata[key.downcase()] = md[1].strip()
			end
		end

		response.artist = metadata["artist"] if metadata.include?( "artist" )
		response.title = metadata["title"] if metadata.include?( "title" )
		response.album = metadata["album"] if metadata.include?( "album" )
		response.year = metadata["year"] if metadata.include?( "year" )

		md = /<\/span> ?<\/center>(.*)<center> ?<span style/.match( page_body )
		return if ! md

		page_body = md[1]
		page_body.sub!( /&#91;.+ Lyrics on http:\/\/#{site_host()}\/ &#93;/, "" )
		page_body.sub!( /^.*<\/a>/, "" ) # additional (optional) crap at the beginning
		page_body.gsub!( /<u>&lt;a[^<]+&lt;\/a&gt;<\/u>/, "" ) # yet more crap
		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
		page_body.sub!( /^\ ?<strong>Lyrics to [^<]+<\/strong> :<\/?br> */i, "" )

		page_body.strip!()

		response.lyrics = page_body

	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist ) )
	end

	def suggestions_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) Lyrics<\/title>/i.match( page_body )
		return md ? Strings.normalize( md[1] ).index( Strings.normalize( request.artist ) ) : nil
	end

	# returns an array of maps with following keys: url, artist, title
	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		# remove table with other artists at the bottom
		return suggestions if ! page_body.sub!( /(.*)<table.*/, "\\1" )

		md = /<table width=100%>(.*)<\/table>/.match( page_body )
		return suggestions if ! md

		md[1].split( /<a href=/ ).each() do |entry|
			if (md = /"(\/lyrics\/[^"]+)" title="[^"]+"> ?([^>]+) lyrics<\/a><br>/.match( entry ))
				suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}#{md[1]}" )
			end
		end

		return suggestions

	end

end
