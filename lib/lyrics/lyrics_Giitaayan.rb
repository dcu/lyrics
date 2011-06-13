# encoding: utf-8
# Copyright (C) 2007-2008 by
# Swapan Sarkar <swapan@yahoo.com>
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
require "utils/itrans"
require "lyrics"

require "cgi"

class Giitaayan < Lyrics

# 	@@prefix = "http://s94437128.onlinehome.us/isb/cisb/"
# 	@@prefix = "http://gaane.giitaayan.com/cisb/"
	@@prefix = "http://thaxi.hsc.usc.edu/rmim/giitaayan/cisb/"
	@@prefix_regexp = /<a href=" *(#{@@prefix.gsub( "\\", "\\\\" ).gsub( ".", "\\." )}[^"]+.isb)">/

	def Giitaayan.site_host()
		return "www.giitaayan.com"
	end

	def Giitaayan.site_name()
		return "Giitaayan"
	end

	def Giitaayan.lyrics_test_data()
		return [
			Request.new( "Abhijit, Kavita Subramaniam", ITRANS.to_devanagari( "a.ndherii raat me.n ham aur tum" ), "Juhi" ),
			Request.new( "Poornima, Chorus", ITRANS.to_devanagari( "a aa ii u u uu meraa dil na to.Do" ), "Raajaa Baabu" ),
			Request.new( "Sonu Nigam, Chorus", ITRANS.to_devanagari("gayaa gayaa dil jaane de" ), "Fizaa" ),
			Request.new( "Lata, Hemant", ITRANS.to_devanagari( "ulajh gaye do nainaa, dekho" ), "Ek Saal" ),
		]
	end

	def Giitaayan.known_url?( url )
		return url.index( @@prefix ) == 0
	end

	def Giitaayan.build_song_add_url( request )
		return "http://#{site_host()}/submit.asp"
	end

	def parse_lyrics( response, page_body )

		custom_data = {}

		["stitle", "film", "year", "starring", "singer", "music", "lyrics"].each() do |key|
			if (md = /\\#{key}\{(.+)\}%/.match( page_body ))
				custom_data[key] = md[1]
			end
		end

		response.artist = custom_data["singer"]
		response.album = custom_data["film"]
		response.year = custom_data["year"]

		custom_data["lyricist"] = custom_data["lyrics"] if ! Strings.empty?( custom_data["lyrics"] )
		if ! Strings.empty?( custom_data["music"] ) || ! Strings.empty?( custom_data["lyrics"] )
			custom_data["credits"] = "#{custom_data["music"]} #{custom_data["lyrics"]}".strip()
		end
		if ! Strings.empty?( custom_data["stitle"] )
			custom_data["stitle"] = ITRANS.to_devanagari( custom_data["stitle"] )
			response.title = custom_data["stitle"]
		end

		response.custom_data = custom_data

		return if ! page_body.gsub!( /^.*\n#indian\s*\n%?/m, "" )
		return if ! page_body.gsub!( /%?\s*\n#endindian.*$/m, "" )

		page_body.gsub!( "\\threedots", "..." )
		page_body.gsub!( "\\-", "-" )
		page_body.gsub!( "\\:", ":" )
		page_body.gsub!( /%[^\n]*/, "" )

		response.lyrics = ITRANS.to_devanagari( page_body )

	end

	def build_suggestions_fetch_data( request )
		title = CGI.escape( ITRANS.from_devanagari( request.title ) )
		return FetchPageData.new( "http://#{site_host()}/search.asp?browse=stitle&s=#{title}" )
	end

	def parse_suggestions( request, page_body, page_url )

		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		return suggestions if page_body.include?( "Sorry, no song found for your search!" )
		return suggestions if ! page_body.sub!( /^.*<div align="center"><b>Lyrics<\/b><\/div> ?<\/td> ?<\/tr> ?<tr>/, "" )
		return suggestions if ! page_body.sub!( /<form name="form1" method="get" action="search\.asp".*$/, "" )

		page_body.gsub!( /<br> ?Page <b>1<\/b> ?<a href="search.asp\?PageNo=2&s=na&browse=stitle">.*$/, "" )

		page_body.split( /<\/tr> ?<tr> ?/ ).each() do |sugg|
			if (md1 = /^ ?<td>([^<]+) - <a/.match( sugg )) && (md2 = @@prefix_regexp.match( sugg ))
				suggestions << Suggestion.new( request.artist, ITRANS.to_devanagari( md1[1] ), md2[1] )
			end
		end

		return suggestions

	end

end
