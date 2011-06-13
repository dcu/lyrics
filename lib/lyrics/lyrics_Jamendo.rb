# encoding: utf-8
# Copyright (C) 2006-2008 by
# Eduardo Robles Elvira <edulix@gmail.com>
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
require "utils/http"
require "lyrics"

class Jamendo < Lyrics

	def Jamendo.site_host()
		return "www.jamendo.com"
	end

	def Jamendo.site_name()
		return "Jamendo"
	end

	def Jamendo.lyrics_test_data()
		return [
			Request.new( "Misantropía", "Hipócrita (Hypocrite)", "Misantropía" ),
			Request.new( "Inesperado", "Pez Gordo", "Maqueta Inesperada" ),
			Request.new( "Black Venus", "Vents de Mars", "Immortel" ),
			Request.new( "Punkamine", "Gora gerra", "Punkamine" ),
		]
	end

	def Jamendo.cleanup_artist_name( artist )
		artist = Strings.downcase( artist )
		Strings.remove_vocal_accents!( artist )
		artist.gsub!( /\[|\]|:/, "" )
		artist.gsub!( /_| |'|"|ø|&|@|\/|\*|\.|®|%|#/, " " ) # \' can also be ''
		artist.squeeze!( " " )
		artist.strip!()
		artist.gsub!( " ", "." )
		return artist
	end

	def cleanup_artist_name( artist )
		self.class.cleanup_artist_name( artist )
	end

	def build_lyrics_fetch_data( request )
		url =  "http://#{site_host()}/en/get/track/list/track-artist-album/lyricstext/plain/?"
		url << "searchterm=#{CGI.escape( request.title )}"
		url << "&artist_searchterm=#{CGI.escape( request.artist )}"
		url << "&album_searchterm=#{CGI.escape( request.album )}" if request.album
		return FetchPageData.new( url )
	end

	def suggestions_page_valid?( request, page_body, page_url )
		return	page_url.index( "http://#{site_host()}/en/artist/" ) ||
				page_url.index( "http://#{site_host()}/en/album/" )
	end

	def parse_lyrics( response, page_body )

		if /track-artist-album/.match( response.url )

			page_body.tr_s!( " \r\t", " " )

			md = /[?&]searchterm=([^&]+)(&?|$)/.match( response.url )
			response.title = CGI.unescape( md[1] ) if md

			md = /[?&]artist_searchterm=([^&]+)(&?|$)/.match( response.url )
			response.artist = CGI.unescape( md[1] ) if md

			md = /[?&]album_searchterm=([^&]+)(&?|$)/.match( response.url )
			response.album = CGI.unescape( md[1] ) if md

			response.lyrics = page_body if ! page_body.empty?

		else

			page_body.tr_s!( " \n\r\t", " " )

			if (md = /<h1>([^<]+)<\/h1><p> by <a href="\/en\/artist\/[^"]+"[^<]*>([^<]+)<\/a>/.match( page_body ))
				response.title = md[1].strip()
				response.artist = md[2].strip()
			end

			if (md = /<a class="i l a" href="http:\/\/#{site_host()}\/en\/album\/[^"]+" ?>([^<]+)<\/a>/.match( page_body ))
				response.album = md[1].strip()
			end

			custom_data = {}
			["release", "genre"].each() do |key|
				md = /<tr class='[a|b]'> ?<td class='l'>#{key}<\/td> ?<td class='[^']+'>([^<]+)<\/td> ?<\/tr>/i.match( page_body )
				custom_data[key] = md[1].strip() if md
			end

			response.custom_data = custom_data
			response.year = custom_data["release"].gsub( /.*,/, "" ) if custom_data.include?( "release" )

			return if ! page_body.sub!( /^.*<div id="lyrics"[^>]*>/, "" )
			return if ! page_body.sub!( /<\/div>.*$/, "" )

			page_body.gsub!( /\ ?<br ?\/?> ?/i, "\n" )

			response.lyrics = page_body

		end

	end

	def build_suggestions_fetch_data( request )
		return FetchPageData.new(
			Strings.build_google_feeling_lucky_url(
				"artist " + Strings.google_search_quote( "albums of #{request.artist}" ),
				"#{site_host()}/en"
			)
		)
	end

	def parse_suggestions( request, page_body, page_url )

		page_body.tr_s!( " \n\r\t", " " )

		suggestions = []

		if page_url.index( "http://#{site_host()}/en/artist/" )

			return suggestions if ! page_body.sub!( /^.*<h2 class="seo_message" ?>Albums of [^<]+<\/h2>/, "" )
			return suggestions if ! page_body.sub!( /<h3>More information...<\/h3>.*$/, "" )

			page_body.split( /<h2 class='g_album_name'>/ ).each() do |album_entry|
				if (md = /<a title="[^"]+" href="(\/en\/album\/[0-9]+)" >([^<]+)<\/a>/.match( album_entry ))
					suggestions << FetchPageData.new( "http://#{site_host()}#{md[1]}" )
				end
			end

		elsif page_url.index( "http://#{site_host()}/en/album/" )

			return suggestions if ! page_body.sub!( /^.*<tbody>/, "" )
			return suggestions if ! page_body.sub!( /<\/tbody>.*$/, "" )

			page_body.split( "<td class=\"title_tracks\">" ).each() do |song_entry|
				if (md = /<a href="(\/en\/track\/[0-9]+)" title="[^"]*" ?>([^<]+)<\/a>/.match( song_entry ))
					suggestions << Suggestion.new( request.artist, md[2].strip(), "http://#{site_host()}#{md[1]}" )
				end
			end

		end

		return suggestions

	end

end
