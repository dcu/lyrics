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

require "utils/strings"
require "lyrics"

class DarkLyrics < Lyrics

	def DarkLyrics.site_host()
		return "www.darklyrics.com"
	end

	def DarkLyrics.site_name()
		return "Dark Lyrics"
	end

	def DarkLyrics.lyrics_test_data()
		return [
			Request.new( "Opeth", "Hope Leaves", "Damnation" ),
			Request.new( "Megadeth", "À tout le monde", "Youthanasia" ),
			Request.new( "Metallica", "Master of Puppets", "Master of Puppets" ),
			Request.new( "Lacuna Coil", "Heaven's a Lie", "Comalies" ),
		]
	end

	def DarkLyrics.build_song_add_url( request )
		return "http://#{site_host()}/submit.html"
	end

	def DarkLyrics.build_google_feeling_lucky_url( artist, title=nil )
		query = Strings.google_search_quote( artist )
		query << " " << Strings.google_search_quote( title ) if title
		query << " lyrics"
		return Strings.build_google_feeling_lucky_url( query, title ? "#{site_host()}/lyrics" : site_host() )
	end

	def build_lyrics_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist, request.title ) )
	end

	def lyrics_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) LYRICS - [^<]+<\/title>/.match( page_body )
		return md ? Strings.normalize( request.artist ) == Strings.normalize( md[1] ) : false
	end

	def parse_lyrics( response, page_body )

# 		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		if (md = /<FONT size=5 color=#FFFFCC>([^<]+) LYRICS<\/FONT><br>/.match( page_body ))
			response.artist = Strings.titlecase( md[1], true, true )
		end

		if (md = /<FONT size=3 color=white><b>([^<]+) \(([0-9]{4,4})( [^\)]+|)\)<\/b><\/FONT><br>/.match( page_body ))
			response.album, response.year = md[1], md[2]
		end

		return if ! page_body.sub!( /^.*<SCRIPT LANGUAGE="javascript" src="\.\.\/\.\.\/recban\.js"><\/SCRIPT><BR>/i, "" )
		return if ! page_body.sub!( /<FONT [^>]*size=.*$/i, "" )

		md = /.*#([0-9]+)$/.match( response.url )
		track = md ? md[1] : nil
		normalized_title = Strings.normalize( response.request.title )
		page_body.split( /<a name=[0-9]+><FONT color=#DDDDDD>/i ).each() do |song_content|
			md = /^<b>([0-9]+)\. ([^<]+)<\/b><\/font><br>(.*)$/.match( song_content )
			next if ! md || (track && track != md[1]) || (! track && normalized_title != Strings.normalize( md[2] ))
			response.title = md[2]
			page_body = md[3]
			page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
			page_body.gsub!( /\n{3,}/, "\n\n" )
			page_body.strip!()
			response.lyrics = page_body
		end

	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist ) )
	end

	def suggestions_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) LYRICS<\/title>/.match( page_body )
		return md ? Strings.normalize( request.artist ) == Strings.normalize( md[1] ) : false
	end

	def parse_suggestions( request, page_body, page_url )

# 		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		return suggestions if ! page_body.sub!(/^.*<FONT FACE="Helvetica" COLOR=#FFFFCC SIZE=4><br>[^<]+ LYRICS<BR><\/FONT>/i,"")
		return suggestions if ! page_body.sub!( /<SCRIPT LANGUAGE="javascript".*$/i, "" )

		page_body.split( /<br>/i ).each() do |entry|
			if (md = /<a href="\.\.(\/lyrics\/[^"]+)" target="_blank"><FONT [^>]+>([^"]+)<\/FONT><\/a>/i.match( entry ))
				suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}#{md[1]}" )
			end
		end

		return suggestions

	end

end
