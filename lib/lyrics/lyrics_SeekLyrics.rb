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
require "lyrics"

class SeekLyrics < Lyrics

	@@white_chars = "'\"¿?¡!()[].,;:-/& "

	def SeekLyrics.site_host()
		return "www.seeklyrics.com"
	end

	def SeekLyrics.site_name()
		return "Seek Lyrics"
	end

	def SeekLyrics.lyrics_test_data()
		return [
			Request.new( "Nirvana", "Smells Like Teen Spirit", "Nevermind" ),
			Request.new( "Radiohead", "Optimistic", "Kid A" ),
			Request.new( "Massive Attack", "Protection", "Protection" ),
			Request.new( "Portishead", "Wandering Star", "Dummy" ),
		]
	end

	def SeekLyrics.build_song_add_url( request )
		return "http://#{site_host()}/submit.php"
	end

	def cleanup_token( token )
		token = token.tr( @@white_chars, " " )
		token.strip!()
		token.tr!( " ", "-" )
		return token
	end

	def build_lyrics_fetch_data( request )
		artist = cleanup_token( request.artist.gsub( /^the /i, "" ) )
		title = cleanup_token( request.title )
		return FetchPageData.new( "http://#{site_host()}/lyrics/#{artist}/#{title}.html", nil, { "Cookie"=>"pass=deleted" } )
	end

	def parse_lyrics( response, page_body )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		page_body.tr_s!( "", "'" )

		if (md = /<b><h2>([^<-]+) - ([^<]+) Lyrics<\/h2><\/b>/i.match( page_body ))
			response.artist, response.title = md[1].strip(), md[2].strip()
		end

		return if ! page_body.sub!( /^(.*)<a href="http:\/\/www\.ringtonematcher\.com.*$/i, "\\1" )
		return if ! page_body.sub!( /^.*<img src="\/images\/phone-right\.gif" [^<]+><\/a>/i, "" )

		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
		page_body.strip!()

		response.lyrics = page_body

	end

	def build_suggestions_fetch_data( request )
		artist = cleanup_token( request.artist.gsub( /^the /i, "" ) )
		return FetchPageData.new( "http://#{site_host()}/lyrics/#{artist}/showall.html", nil, { "Cookie"=>"pass=deleted" } )
	end

	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		page_body.tr_s!( "", "'" )

		suggestions = []

		return suggestions if ! page_body.gsub!( /.*<tr><td width="50%"><\/td><td width="50%"><\/td><\/tr>/, "" )
		return suggestions if ! page_body.gsub!( /<\/table>.*$/, "" )

		page_body.split( /<td>&nbsp;-&nbsp;&nbsp;/i ).each() do |entry|
			if (md = /<a href="([^"]+)"[^>]*>([^<]+)<\/a><\/td>/i.match( entry ))
				suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}#{md[1]}" )
			end
		end

		return suggestions

	end

end
