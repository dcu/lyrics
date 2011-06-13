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
require "utils/htmlentities"
require "lyrics"

require "cgi"

class LeosLyrics < Lyrics

	def LeosLyrics.site_host()
		return "www.leoslyrics.com"
	end

	def LeosLyrics.site_name()
		return "Leos Lyrics"
	end

	def LeosLyrics.lyrics_test_data()
		return [
			Request.new( "Cat Power", "Good Woman", "You Are Free" ),
			Request.new( "Blur", "No Distance Left To Run", "13" ),
			Request.new( "Massive Attack", "Angel", "Mezzanine" ),
			Request.new( "Nirvana", "All Apologies", "In Utero" ),
			# Request.new( "System Of A Down", "Chop Suey", "Toxicity" ),
			# Request.new( "A Perfect Circle", "The Noose", "Thirteen Step" ),
		]
	end

	def LeosLyrics.build_song_add_url( request )
		add_url =  "http://#{site_host()}/submit.php?artist=#{CGI.escape( request.artist )}&song=#{CGI.escape( request.title )}"
		add_url << "&album=#{CGI.escape( request.album )}" if request.album
		return add_url
	end

	def lyrics_page_valid?( request, page_body, page_url )
		md = /<TITLE>([^<]+)-\s*([^<]+)\s*lyrics\s*<\/TITLE>/im.match( page_body )
		return false if ! md
		return	Strings.normalize( request.artist ) == Strings.normalize( md[1] ) &&
				Strings.normalize( request.title ) == Strings.normalize( md[2] )
	end

	def parse_lyrics( response, page_body )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		HTMLEntities.decode!( page_body )

		if (md = /<TITLE> ?(.+) ?- ?(.+) ?lyrics ?<\/TITLE>/.match( page_body ))
			response.artist, response.title = md[1].strip(), md[2].strip()
		end

		if (md = /<font face="[^"]+" size=-1>(.+)<\/font>/.match( page_body ))
			page_body = md[1]
			page_body.gsub!( /<\/font>.*/, "" )
			page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
			page_body.gsub!( /\n{3,}/, "\n\n" )
			response.lyrics = page_body
		end

	end

	# # site's search is currently disabled
	# def build_suggestions_fetch_data( request )
	# 	artist = CGI.escape( Strings.utf82latin1( request.artist ) )
	# 	title = CGI.escape( Strings.utf82latin1( request.title ) )
	# 	return FetchPageData.new( "http://#{site_host()}/advanced.php?artistmode=1&artist=#{artist}&songmode=1&song=#{title}&mode=0" )
	# end

	def build_suggestions_fetch_data( request )
		artist = CGI.escape( Strings.utf82latin1( request.artist ) )
		title = CGI.escape( Strings.utf82latin1( request.title ) )
		return FetchPageData.new( "http://#{site_host()}/search.php?search=#{artist}+#{title}&sartist=1&ssongtitle=1" )
	end

	# def suggestions_page_valid?( request, page_body, page_url )
	# 	md = /<TITLE>\s*Leo's Lyrics Database\s*-\s*([^<]+)\s*lyrics\s*<\/TITLE>/im.match( page_body )
	# 	return md ? Strings.normalize( request.artist ) == Strings.normalize( md[1] ) : false
	# end

	# def parse_suggestions( request, page_body, page_url )
	#
	# 	page_body = Strings.latin12utf8( page_body )
	# 	page_body.tr_s!( " \n\r\t", " " )
	# 	HTMLEntities.decode!( page_body )
	#
	# 	suggestions = []
	#
	# 	md = /<ul>(.*)<\/ul>/i.match( page_body )
	# 	return suggestions if ! md
	#
	# 	md[1].split( "<li>" ).each do |entry|
	# 		if (md = /<a href="(\/listlyrics.php;jsessionid=[^"]+)">([^<]+) Lyrics<\/a>/.match( entry ))
	# 			suggestions << Suggestion.new( request.artist, md[2], "http://#{site_host()}#{md[1]}" )
	# 		end
	# 	end
	#
	# 	return suggestions
	#
	# end

	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		HTMLEntities.decode!( page_body )

		suggestions = []

		return suggestions if ! page_body.sub!( /^.*<table border=0 width="100%">/, "" )
		return suggestions if ! page_body.sub!( /<\/table>.*$/, "" )

		page_body.split( /<tr> ?<td>/ ).each do |entry|
			entry.gsub!( /\ *<\/?(td|b|font)[^>]*> */, "" )
			if (md = /<a href="\/artists\/[^"]+">([^<]+)<\/a><a href="([^"]+)">([^<]+)<\/a>/.match( entry ))
				suggestions << Suggestion.new( md[1], md[3], "http://#{site_host()}#{md[2]}" )
			end
		end

		return suggestions

	end

end
