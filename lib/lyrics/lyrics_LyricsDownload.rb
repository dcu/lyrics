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
require "lyrics"

class LyricsDownload < Lyrics

	@@white_chars = "'\"¿?¡!()[].,;:-/& "

	def LyricsDownload.site_host()
		return "www.lyricsdownload.com"
	end

	def LyricsDownload.site_name()
		return "Lyrics Download"
	end

	def LyricsDownload.lyrics_test_data()
		return [
			Request.new( "Nirvana", "Smells Like Teen Spirit", "Nevermind" ),
			Request.new( "Radiohead", "Optimistic", "Kid A" ),
			Request.new( "Massive Attack", "Protection", "Protection" ),
			Request.new( "Portishead", "Wandering Star", "Dummy" ),
		]
	end

	def cleanup_artist( artist )
		artist = artist.gsub( /^the /i, "" )
		Strings.remove_vocal_accents!( artist )
		artist.gsub!( "&", "and" )
		artist.tr!( @@white_chars, " " )
		artist.strip!()
		artist.tr!( " ", "-" )
		return artist
	end

	def cleanup_title( title )
		title = Strings.remove_vocal_accents( title )
		title.gsub!( "&", "and" )
		title.tr!( @@white_chars, " " )
		title.strip!()
		title.tr!( " ", "-" )
		return title
	end

	def build_lyrics_fetch_data( request )
		artist = cleanup_title( request.artist )
		title = cleanup_title( request.title )
		return FetchPageData.new( "http://#{site_host()}/#{artist}-#{title}-lyrics.html" )
	end

	def parse_lyrics( response, page_body )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		page_body.tr_s!( "", "'" )
# 		page_body.tr_s!( "‘", "'" )

		if (md = /<title>([^<]+) - ([^<]+) LYRICS ?<\/title>/i.match( page_body ))
			response.artist, response.title = md[1].strip(), md[2].strip()
		end

		return if ! page_body.gsub!( /^.*<div class="KonaBody" ><div id="div_customCSS">/, "" )
		return if ! page_body.gsub!( /<\/div> ?<\/div>.*$/, "" )

		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
		page_body.strip!()

		response.lyrics = page_body

	end

	def build_suggestions_fetch_data( request )
		artist = cleanup_artist( request.artist )
		return FetchPageData.new( "http://#{site_host()}/#{artist}-lyrics.html" )
	end

	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		page_body.tr_s!( "", "'" )

		suggestions = []

		return suggestions if ! page_body.sub!( /^.*Lyrics list aplhabetically:<\/font><\/td>/, "" )
		return suggestions if ! page_body.sub!( /<\/ul> ?<\/td> ?<\/tr> ?<\/table> ?<center><div>.*$/, "" )

		page_body.split( "</li>" ).each() do |entry|
			if (md = /<a class="txt_1" href="([^"]+)"><font size=2>([^<]+) Lyrics<\/font><\/a>/.match( entry ))
				suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}/#{md[1]}" )
			end
		end

		return suggestions

	end

end
