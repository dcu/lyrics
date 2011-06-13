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

class TerraLetras < Lyrics

	def TerraLetras.site_host()
		return "letras.terra.com.br"
	end

	def TerraLetras.site_name()
		return "Terra Letras"
	end

	def TerraLetras.known_url?( url )
		return url.index( "http://#{site_host}" ) == 0 || /^http:\/\/.*\.letras\.terra\.com\.br\/letras\/[0-9]+/.match( url )
	end

	def TerraLetras.lyrics_test_data()
		return [
			Request.new( "The Cranberries", "Linger", "Everybody Else Is Doing It, So Why Can't We?" ),
			Request.new( "Radiohead", "Optimistic", "Kid A" ),
			Request.new( "Mark Lanegan", "One Way Street", "Field Songs" ),
			Request.new( "U2", "One", "Achtung Baby" ),
		]
	end

	def TerraLetras.build_song_add_url( request )
		return "http://#{site_host()}/envie_artista.php"
	end

	def TerraLetras.build_google_feeling_lucky_url( artist, title=nil )
		if title
			query = Strings.google_search_quote( "#{title} letra" )
			query << " "
			query << Strings.google_search_quote( artist )
		else
			query = Strings.google_search_quote( "letras de #{artist}" )
			query << " "
			query << Strings.google_search_quote( "#{artist} letras" )
		end
		return Strings.build_google_feeling_lucky_url( query, site_host() )
	end

	def build_lyrics_fetch_data( request )
		artist = Strings.utf82latin1( request.artist )
		title  = Strings.utf82latin1( request.title )
		return FetchPageData.new( "http://#{site_host()}/winamp.php?musica=#{CGI.escape(title)}&artista=#{CGI.escape(artist)}" )
	end

	def parse_lyrics( response, page_body )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )

		if response.url.index( "http://#{site_host}/winamp.php?" ) == 0 # direct fetch
			if (md = /<h1><a href='[^']+' target='_blank'>([^<]+)<\/a><\/h1>/.match( page_body ))
				response.title = md[1]
			end
			if (md = /<h2><a href='[^']+' target='_blank'>([^<]+)<\/a><\/h2>/.match( page_body ))
				response.artist = md[1]
			end
			return if ! page_body.gsub!( /^.*corrigir letra<\/a><\/p><p>/, "" )
			return if ! page_body.gsub!( /<\/p>.*$/, "" )
		else # fetched from suggestions/url
			if (md = /<h2>([^<]+)<\/h2> <h2 id='sz'>([^<]+)<\/h2>/.match( page_body ))
				response.title, response.artist = md[1], md[2]
			end
			return if ! page_body.sub!( /^.*<p id='cmp'>[^<]*<\/p> <p>/, "" )
			return if ! page_body.sub!( /<\/p>.*/, "" )
		end

		page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )
		page_body.gsub!( /\n{3,}/, "\n\n" )
		response.lyrics = page_body

	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new( build_google_feeling_lucky_url( request.artist ) )
	end

	def parse_suggestions( request, page_body, page_url )

		page_body = Strings.latin12utf8( page_body )
		page_body.tr_s!( " \n\r\t", " " )
		HTMLEntities.decode!( page_body )

		suggestions = []

		return suggestions if ! page_body.gsub!( /^.*<ul class='top' id='bgn'>/, "" )
		return suggestions if ! page_body.gsub!( /<\/ul>.*$/, "" )

		page_body.split( /<\/li> ?<li>/ ).each do |entry|
			if (md = /<a href="([^"]+)">([^<]+) - ([^<]+)<\/a>/.match( entry ))
				suggestions << Suggestion.new( md[2], md[3], "http://#{site_host()}#{md[1]}" )
			end
		end

		return suggestions

	end

end
