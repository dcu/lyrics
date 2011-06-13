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

require "lyrics"

class Sing365 < Lyrics

	def Sing365.site_host()
		return "www.sing365.com"
	end

	def Sing365.site_name()
		return "Sing365"
	end

	def Sing365.lyrics_test_data()
		return [
			Request.new( "Nirvana", "Smells Like Teen Spirit", "Nevermind" ),
			Request.new( "The Cranberries", "Linger", "Everybody Else Is Doing It, So Why Can't We?" ),
			Request.new( "Pearl Jam", "Porch", "Ten" ),
			Request.new( "The Smashing Pumpkins", "Mayonaise", "Siamese Dream" ),
		]
	end

	def Sing365.build_song_add_url( request )
		return build_google_feeling_lucky_url( request.artist )
	end

	def build_lyrics_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist, request.title ) )
	end

	def lyrics_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) - ([^<]+) LYRICS<\/title>/i.match( page_body )
		return md ?
			Strings.normalize( request.artist ) == Strings.normalize( md[1] ) &&
			Strings.normalize( request.title ) == Strings.normalize( md[2] ) :
			false
	end

	def parse_lyrics( response, page_body )

		page_body.tr_s!( " \n\r\t", " " )

		if (md = /<meta name="Description" content="([^"]+) lyrics performed by ([^"]+)">/i.match( page_body ))
			response.artist, response.title = md[1], md[2]
		end

		return if ! (md = /<img src="?http:\/\/#{site_host()}\/images\/phone2\.gif"? border="?0"?><br><br><\/div>(.*)<div align="?center"?><br><br><img src="?http:\/\/#{site_host()}\/images\/phone\.gif"?/i.match( page_body ))

		page_body = md[1]
		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
		page_body.gsub!( /\n{3,}/, "\n\n" )

		response.lyrics = page_body

	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist ) )
	end

	def suggestions_page_valid?( request, page_body, page_url )
		md = /<title>([^<]+) LYRICS<\/title>/i.match( page_body )
		return md ? Strings.normalize( request.artist ) == Strings.normalize( md[1] ) : false
	end

	def parse_suggestions( request, page_body, page_url )

		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		return suggestions if ! (md = /<img src="?http:\/\/#{site_host()}\/images\/phone2\.gif"? border="?0"?><br><br><\/div>(.*)<\/lu><br><div align="?center"?><br><img src="?http:\/\/#{site_host()}\/images\/phone\.gif"?/i.match( page_body ))

		md[1].split( "<li>" ).each() do |entry|
			if (md = /<a href="([^"]+)"[^>]*>([^<]+) Lyrics<\/a>/i.match( entry ))
				suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}#{md[1]}" )
			end
		end

		return suggestions

	end

end
