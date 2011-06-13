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
require "utils/http"
require "mediawikilyrics"

require "cgi"
require "uri"

class LyricWiki < MediaWikiLyrics

	def LyricWiki.site_host()
		return "lyricwiki.org"
	end

	def LyricWiki.site_name()
		return "LyricWiki"
	end

	def LyricWiki.control_page()
		return "LyricWiki:Wiki-Lyrics"
	end

	def parse_lyrics( response, page_body )

		page_body.gsub!( /â€™|�/, "'" ) # replace bizarre characters with apostrophes

		custom_data = {}
		custom_data["reviewed"] = (/\[\[Category:[Rr]eview[_ ]Me\]\]/.match( page_body ) == nil)

		# search album, year and artist information
		if (md = /\{\{\s*[Ss]ong\s*\|.*$/.match( page_body ))
			unnamed_params_names = { 1 => "album_and_year", 2 => "artist" }
			template_data = parse_template( md[0] )
			template_data["params"].each() do |key, value|
				if (key = unnamed_params_names[key]) && value.is_a?( String )
					custom_data[key] = value
				end
			end
			if custom_data["reviewed"] && template_data["params"]["star"] == "Green"
				custom_data["reviewed"] = false
			end
		elsif (md = /On (''')?\[\[[^\|]+\|([^\|]+)\]\](''')? by (''')?\[\[([^\]]+)\]\](''')?/.match( page_body ))
			custom_data["album_and_year"] = md[2]
			custom_data["artist"] = md[5]
		end

		if custom_data.include?( "album_and_year" )
			if (md = /^(.+) \(([\?0-9]{4,4})\)$/.match( custom_data["album_and_year"] ))
				response.album = md[1]
				response.year = md[2] if md[2].to_i() > 1900
			end
		end

		# search title information (and other information that hasn't been found yet)
		if (md = /\{\{\s*[Ss]ongFooter\s*\|.*$/.match( page_body ))
			template_data = parse_template( md[0] )
			template_data["params"].each() do |key, value|
				custom_data[key.to_s()] = value if value.is_a?( String )
			end
		elsif (md = /\[[^\s\]]+ ([^\]]+)\] on Amazon$/.match( page_body ))
			custom_data["song"] = md[1].strip()
		end

		if (md = /\*?\s*Composer: *([^\n]+)/.match( page_body ))
			custom_data["credits"] = md[1].strip()
		end

		if (md = /\*?\s*Lyrics by: *([^\n]+)/.match( page_body ))
			custom_data["lyricist"] = md[1].strip()
		end

		response.artist = custom_data["artist"] if custom_data.include?( "artist" )
		response.title = custom_data["song"] if custom_data.include?( "song" )
		response.album = custom_data["album"] if custom_data.include?( "album" )

		if (md = /<lyrics?>(.*)<\/lyrics?>/im.match( page_body ))
			page_body = md[1]
			if /\s*\{\{[Ii]nstrumental\}\}\s*/.match( page_body )
				page_body = "<tt>(Instrumental)</tt>"
			else
				page_body.gsub!( /[ \t]*[\r\n][ \t]*/m, "\n" )
			end
		else
			if /\s*\{\{[Ii]nstrumental\}\}\s*/.match( page_body )
				page_body = "<tt>(Instrumental)</tt>"
			else
				page_body.gsub!( /\{\{.*\}\}\n?/, "" )
				page_body.gsub!( /\[\[Category:.*\]\]\n?/, "" )
				page_body.gsub!( /On '''\[\[.*?\n/i, "" )
				page_body.gsub!( /By '''\[\[.*?\n/i, "" )
				page_body.gsub!( /\ *== *Credits *==.*$/im, "" )
				page_body.gsub!( /\ *== *(External *Links|Links) *==.*$/im, "" )
				page_body = page_body.split( "\n" ).collect() do |line|
					if line.index( /\s/ ) == 0
						"\n" + line
					else
						line
					end
				end.join( "" )
				page_body.gsub!( /\s*<br ?\/?>\s*/i, "\n" )
			end
		end

		response.custom_data = custom_data

		if ! Strings.empty?( page_body )
			# expand ruby tags:
			page_body.gsub!( /\{\{ruby\|([^\|]*)\|([^\}]*)\}\}/, "<ruby><rb>\1</rb><rp>(</rp><rt>\2</rt><rp>)</rp></ruby>" )
			# take care of multiple lyrics tags:
			page_body.gsub!( /(\{\|\s*\|-\s*\||\|\|)\s*==\s*([^=]+)\s*==/, "<br/><b>\2</b>" )
			page_body.gsub!( /\s*==\s*([^=]+)\s*==/, "\n<br/><b>\\1</b>" )
			page_body.gsub!( /<\/?lyric>/i, "" )
			response.lyrics = page_body
		end

	end

	def LyricWiki.parse_search_results( page_body, content_matches=true )

		results = []
		return results if page_body == nil || ! content_matches

		page_body.tr_s!( " \n\r\t", " " )
		page_body.gsub!( /\ ?<\/?span[^>]*> ?/, "" )

		return results if ! page_body.sub!( /^.*<h1 class="firstHeading">Search results<\/h1>/, "" )

		return results if ! page_body.gsub!( /<form id="powersearch" method="get" action="[^"]+">.*$/, "" )
		page_body.gsub!( /<\/[uo]l> ?<p( [^>]*|)>View \(previous .*$/, "" )

		page_body.split( "<li>" ).each() do |entry|
			if (md = /<a href="([^"]*index\.php\/|[^"]*index\.php\?title=|\/)([^"]*)" title="([^"]+)"/.match( entry ))
				result = {
					@@SEARCH_RESULT_URL => "http://#{site_host()}/index.php?title=#{md[2]}",
					@@SEARCH_RESULT_TITLE => md[3]
				}
				results << result if ! content_matches || ! results.include?( result )
			end
		end

		return results
	end

	def LyricWiki.build_tracks( album_data )
		ret = ""
		tracks.each() do |track|
			track_artist = cleanup_title_token( track.artist )
			track_title  = cleanup_title_token( track.title )
			tc_track_title = Strings.titlecase( track_title )
			# artist_param = (album_artist == "(Various Artists)" || album_artist == "Various Artists") ? "by" : "artist"
			# ret += "# {{track|title=#{track_title}|#{artist_param}=#{track_artist}}}\n"
			# ret += "# {{track|title=#{track_title}|#{artist_param}=#{track_artist}|display=#{tc_track_title}}}\n"
			ret += "# '''[[#{track_artist}:#{track_title}|#{tc_track_title}]]'''\n"
		end
		return ret
	end

	def LyricWiki.build_album_page( reviewed, artist, album, year, month, day, tracks, album_art )

		raise ArgumentError if Strings.empty?( artist ) || Strings.empty?( album ) || Strings.empty?( tracks )

		f_letter = get_first_letter( album )

		contents = \
		"{{Album\n" \
		"|Artist   = #{artist}\n" \
		"|Album    = #{album}\n" \
		"|fLetter  = #{f_letter}\n" \
		"|Released = #{year}\n" \
		"|Length   = #{year}\n" \
		"|Cover    = #{album_art}\n" \
		"|star     = #{reviewed ? "Black" : "Green"}\n" \
		"}}\n"

		return \
		"#{contents}\n" \
		"#{tracks.strip()}\n" \
		"\n" \
		"{{AlbumFooter\n" \
		"|artist=#{artist}\n" \
		"|album=#{album}\n" \
		"}}\n"
	end

	def LyricWiki.build_song_page( reviewed, artist, title, album, year, credits, lyricist, lyrics )

		raise ArgumentError if artist == nil || title == nil

		f_letter = get_first_letter( title )
		year = year.to_i() > 1900 ? year.to_s() : "????"

		lyrics = lyrics.gsub(
			/<ruby><rb>([^<]*)<\/rb><rp>\(<\/rp><rt>([^<]*)<\/rt><rp>\)<\/rp><\/ruby>/,
			"{{ruby|\1|\2}}"
		) if lyrics

		song_album = Strings.empty?( album ) ? "" : "#{album} (#{year})"
		song_star = reviewed ? "Black" : "Green"

		song_credits = ""
		song_credits << "==Credits==\n" if ! Strings.empty?( credits ) || ! Strings.empty?( lyricist )
		song_credits << "*Composer: #{credits}\n" if ! Strings.empty?( credits )
		song_credits << "*Lyrics by: #{lyricist}\n" if ! Strings.empty?( lyricist )

		return \
		"{{Song|#{song_album}|#{artist}|star=#{song_star}}\n\n" \
		"<lyric>\n#{Strings.empty?( lyrics ) ? "{{instrumental}}" : lyrics}\n</lyric>\n\n" \
		"#{song_credits}\n" \
		"{{SongFooter\n" \
		"|fLetter=#{f_letter}\n" \
		"|artist=#{artist}\n" \
		"|song=#{title}\n" \
		"|album=#{album}\n" \
		"|language=\n" \
		"|iTunes=\n" \
		"}}\n"

	end

	def LyricWiki.build_album_art_name( artist, album, year, extension="jpg", cleanup=true )
		if cleanup
			artist = cleanup_title_token( artist )
			album = cleanup_title_token( album )
		end
		album_art_name = "#{artist} - #{album}#{Strings.empty?( extension ) ? "" : ".#{extension.strip()}"}".gsub( " ", "_" )
		return Strings.remove_invalid_filename_chars( album_art_name )
	end

	def LyricWiki.build_album_art_description( artist, album, year, cleanup=true )
		if cleanup
			artist = cleanup_title_token( artist )
			album = cleanup_title_token( album )
		end
		return \
		"{{Albumcover/Upload|\n" \
		"|artist = #{artist}\n" \
		"|album  = #{album}\n" \
		"|year   = #{year}\n" \
		"}}\n"
	end

	def LyricWiki.find_album_art_name( artist, album, year )

		normalized_artist = cleanup_title_token( artist )
		Strings.remove_invalid_filename_chars!( normalized_artist )
		Strings.normalize!( normalized_artist )
		normalized_artist.gsub!( " ", "" )

		normalized_album = cleanup_title_token( album )
		Strings.remove_invalid_filename_chars!( normalized_album )
		Strings.normalize!( normalized_album )
		normalized_album.gsub!( " ", "" )

		artist = cleanup_title_token( artist )
		Strings.remove_invalid_filename_chars!( artist )
		search_url = "http://#{site_host()}/index.php?ns6=1&search=#{CGI.escape( artist )}&searchx=Search&limit=500"
		response, search_url = HTTP.fetch_page_get( search_url )

		return nil if response == nil || response.body() == nil

		candidates = []
		parse_search_results( response.body(), true ).each() do |result|

			next if result["title"].index( "Image:" ) != 0

			normalized_title = Strings.normalize( result["title"] )
			normalized_title.gsub!( " ", "" )

			matches = 0
			idx1 = normalized_title.index( normalized_artist )
			matches += 1 if idx1
			idx1 = idx1 ? idx1 + normalized_artist.size : 0
			idx2 = normalized_title.index( normalized_album, idx1 )
			matches += 2 if idx2

			candidates.insert( -1, [ matches, result["title"] ] ) if matches > 1
		end

		if candidates.size > 0
			candidates.sort!() { |x,y| y[0] <=> x[0] }
			return URI.decode( candidates[0][1].slice( "Image:".size..-1 ).gsub( " ", "_" ) )
		else
			return nil
		end
	end

	def LyricWiki.get_first_letter( title )
		if title.index( /^[a-zA-Z]/ ) == 0
			return title.slice( 0, 1 )
		elsif title.index( /^[0-9]/ ) == 0
			return "0-9"
		else
			return "Symbol"
		end
	end

	def LyricWiki.cleanup_title_token!( title, downcase=false )
		title.gsub!( /\[[^\]\[]*\]/, "" )
		title.gsub!( /[\[|\]].*$/, "" )
		title.gsub!( /`|´|’/, "'" )
		title.gsub!( /''|«|»/, "\"" )
		title.squeeze!( " " )
		title.strip!()
		title.gsub!( "+", "and" )
		Strings.titlecase!( title, false, downcase )
		return title
	end

end
