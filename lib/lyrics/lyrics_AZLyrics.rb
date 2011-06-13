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

class AZLyrics < Lyrics

	def AZLyrics.site_host()
		return "www.azlyrics.com"
	end

	def AZLyrics.site_name()
		return "AZ Lyrics"
	end

	def AZLyrics.lyrics_test_data()
		return [
			Request.new( "Radiohead", "Optimistic", "Kid A" ),
			Request.new( "Pearl Jam", "Alive", "Ten" ),
			Request.new( "Massive Attack", "Protection", "Protection" ),
			Request.new( "Portishead", "Wandering Star", "Dummy" ),
		]
	end

	def AZLyrics.build_song_add_url( request )
		return "http://#{site_host()}/add.html"
	end

	def AZLyrics.build_google_feeling_lucky_url( artist, title=nil )
		query = Strings.google_search_quote( artist )
		query << " " << Strings.google_search_quote( title ) if title
		query << " lyrics"
		return Strings.build_google_feeling_lucky_url( query, title ? "#{site_host()}/lyrics" : site_host() )
	end

	def build_lyrics_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist, request.title ) )
	end

	def lyrics_page_valid?( request, page_body, page_url )
		md = /<TITLE>([^<]+) LYRICS - ([^<]+)<\/TITLE>/.match( page_body )
		return md ?
			Strings.normalize( request.artist ) == Strings.normalize( md[1] ) &&
			Strings.normalize( request.title ) == Strings.normalize( md[2] ) :
			false
	end

	def parse_lyrics( response, page_body )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		if (md = /<B>([^<]+) LYRICS ?<\/B> ?<BR> ?<BR> ?<FONT size=2> ?<B> ?"([^<]+)" ?<\/b>/.match( page_body ))
			response.artist, response.title = Strings.titlecase( md[1], true, true ), md[2]
		end

		return if ! page_body.sub!( /^.*"<\/b><BR> ?<BR> ?/i, "" )
		return if ! page_body.sub!( /\ ?<BR> ?<BR> ?\[ <a href=.*$/i, "" )

		page_body.gsub!( /<i>\[Thanks to.*$/i, "" )
		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
		page_body.gsub!( /\n{3,}/, "\n\n" )

		response.lyrics = page_body
	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist ) )
	end

	def suggestions_page_valid?( request, page_body, page_url )
		md = /<TITLE>([^<]+) lyrics<\/TITLE>/.match( page_body )
		return md ? Strings.normalize( request.artist ) == Strings.normalize( md[1] ) : false
	end

	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		return suggestions if ! page_body.gsub!( /.*<tr><td align=center valign=top> <font face=verdana size=5><br> ?<b>[^<]+ lyrics<\/b>/i, "" )
		return suggestions if ! page_body.gsub!( /<\/font> ?<\/font> ?<\/td> ?<\/tr> ?<\/table>.*$/i, "" )

		page_body.split( /<br>/i ).each() do |entry|
			if (md = /<a href="\.\.([^"]+)" target="_blank">([^<]+)<\/a>/i.match( entry ))
				suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}#{md[1]}" )
			end
		end

		return suggestions
	end

end
