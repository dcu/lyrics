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

require File.expand_path( File.dirname( __FILE__ ) + "/htmlentities" )

require "cgi"

if RUBY_VERSION < "1.9.0"
  $KCODE="u" # unicode support
end

module Strings

	@@word_separators = " \t\n()[],.;:-¿?¡!\"/\\"

	def Strings.empty?( text )
		text = text.to_s()
		return  text.empty? ? true : text.strip.empty?
	end

	def Strings.shell_quote( text )
		return "\"" + text.gsub( "\\", "\\\\\\" ).gsub( "\"", "\\\"" ).gsub( "`", "\\\\`" ) + "\""
	end

	def Strings.shell_unquote( text )
		if text.slice( 0, 1 ) == "\""
			return text.gsub( "\\`", "`" ).gsub( "\\\"", "\"" ).slice( 1..-2 )
		else # if text.slice( 0, 1 ) == "'"
			return text.slice( 1..-2 )
		end
	end

	def Strings.shell_escape( text )
		return text.gsub( "\\", "\\\\\\" ).gsub( "\"", "\\\"" ).gsub( "`", "\\\\`" ).gsub( %q/'/, %q/\\\'/ ).gsub( " ", "\\ " )
	end

	def Strings.shell_unescape( text )
		return text.gsub( "\\ ", " " ).gsub( "\\'", "'" ).gsub( "\\`", "`" ).gsub( "\\\"", "\"" )
	end

	def Strings.sql_quote( text )
		return "'" + Strings.sql_escape( text ) + "'"
	end

	def Strings.sql_unquote( text )
		return Strings.sql_unescape( text.slice( 1..-2 ) )
	end

	def Strings.sql_escape( text )
		return text.gsub( "'", "''" )
	end

	def Strings.sql_unescape( text )
		return text.gsub( "''", "'" )
	end

	def Strings.random_token( length=10 )
		chars = ( "a".."z" ).to_a() + ( "0".."9" ).to_a()
		token = ""
		1.upto( length ) { |i| token << chars[rand(chars.size-1)] }
		return token
	end

	def Strings.remove_invalid_filename_chars( filename )
		return Strings.remove_invalid_filename_chars!( String.new( filename ) )
	end

	def Strings.remove_invalid_filename_chars!( filename )
		filename.tr_s!( "*?:|/\\<>", "" )
		return filename
	end

	def Strings.remove_vocal_accents( text )
		return Strings.remove_vocal_accents!( String.new( text ) )
	end

	def Strings.remove_vocal_accents!( text )
		text.gsub!( /á|à|ä|â|å|ã/, "a" )
		text.gsub!( /Á|À|Ä|Â|Å|Ã/, "A" )
		text.gsub!( /é|è|ë|ê/, "e" )
		text.gsub!( /É|È|Ë|Ê/, "E" )
		text.gsub!( /í|ì|ï|î/, "i" )
		text.gsub!( /Í|Ì|Ï|Î/, "I" )
		text.gsub!( /ó|ò|ö|ô/, "o" )
		text.gsub!( /Ó|Ò|Ö|Ô/, "O" )
		text.gsub!( /ú|ù|ü|û/, "u" )
		text.gsub!( /Ú|Ù|Ü|Û/, "U" )
		return text
	end

	def Strings.google_search_quote( text )
		text = text.gsub( "\"", "" )
		text.gsub!( /^\ *the\ */i, "" )
		return Strings.empty?( text) ? "" : "\"#{text}\""
	end

	def Strings.build_google_feeling_lucky_url( query, site=nil )
		url = "http://www.google.com/search?q=#{CGI.escape( query )}"
		url += "+site%3A#{site}" if site
		return url + "&btnI"
	end

	def Strings.downcase( text )
		begin
			return text.to_s().unpack( "U*" ).collect() do |c|
				if c >= 65 && c <= 90 # abcdefghijklmnopqrstuvwxyz
					c + 32
				elsif c >= 192 && c <= 222 # ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞ
					c + 32
				else
					c
				end
			end.pack( "U*" )
		rescue Exception # fallback to normal operation on error
			return text.downcase()
		end
	end

	def Strings.downcase!( text )
		return text.replace( Strings.downcase( text ) )
	end

	def Strings.upcase( text )
		begin
			return text.to_s().unpack( "U*" ).collect() do |c|
				if c >= 97 && c <= 122 # ABCDEFGHIJKLMNOPQRSTUVWXYZ
					c - 32
				elsif c >= 224 && c <= 254 # àáâãäåæçèéêëìíîïðñòóôõö×øùúûüýþ
					c - 32
				else
					c
				end
			end.pack( "U*" )
		rescue Exception # fallback to normal operation on error
			return text.upcase()
		end
	end

	def Strings.upcase!( text )
		return text.replace( Strings.upcase( text ) )
	end

	def Strings.capitalize( text, downcase=false, first_only=false )
		text = downcase ? Strings.downcase( text ) : text.to_s()
		if first_only
			text.sub!( /^([0-9a-zA-Zàáâãäåæçèéêëìíîïðñòóôõö×øùúûüýþÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞ])/ ) {|c| Strings.upcase( c ) }
		else
			text.sub!( /([0-9a-zA-Zàáâãäåæçèéêëìíîïðñòóôõö×øùúûüýþÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞ])/ ) {|c| Strings.upcase( c ) }
		end
		return text
	end

	def Strings.capitalize!( text, downcase=false, first_only=false )
		return text.replace( Strings.capitalize( text, downcase, first_only ) )
	end

	def Strings.titlecase( text, correct_case=true, downcase=false )
		text = Strings.capitalize( text, downcase )
		word_start = true
		text = text.unpack( "U*" ).collect() do |c|
			if word_start
				chr = [c].pack( "U*" )
				if ! @@word_separators.include?( chr )
					word_start = false
					c = Strings.upcase( chr ).unpack( "U*" )[0]
				end
			else
				chr = c < 256 ? c.chr() : [c].pack( "U*" )
				word_start = true if @@word_separators.include?( chr )
			end
			c
		end.pack( "U*" )
		if correct_case
			lc_words = [
				"the", "a", "an", # articles
				"and", "but", "or", "nor", # conjunctions
				"'n'", "'n", "n'", # and contractions
				"as", "at", "by", "for", "in", "of", "on", "to", # short prepositions
				#"from", "into", "onto", "with", "over" # not so short prepositions
				"feat", "vs", # special words
			]
			lc_words.each() do |lc_word|
				text.gsub!( /\ #{lc_word}([ ,;:\.-?!\"\/\\\)])/i, " #{lc_word}\\1" )
			end
		end
		return text
	end

	def Strings.titlecase!( text, correct_case=true, downcase=false )
		return text.replace( Strings.titlecase( text, correct_case, downcase ) )
	end

	def Strings.normalize( token )
		token = Strings.downcase( token )
		token.tr_s!( " \n\r\t.;:()[]", " " )
		token.strip!()
		token.gsub!( /`|´|’/, "'" )
		token.gsub!( /''|«|»/, "\"" )
		token.gsub!( /[&+]/, "and" )
		token.gsub!( /\ ('n'|'n|n') /, " and " )
		token.gsub!( /^the /, "" )
		token.gsub!( /, the$/, "" )
		return token
	end

	def Strings.normalize!( token )
		return token.replace( Strings.normalize( token ) )
	end

	def Strings.decode_htmlentities!( var )
		if var.is_a?( String )
			HTMLEntities.decode!( var )
		elsif var.is_a?( Hash )
			var.each() { |key, value| decode_htmlentities!( value ) }
		end
		return var
	end

	def Strings.decode_htmlentities( var )
		if var.is_a?( String )
			return HTMLEntities.decode( var )
		elsif var.is_a?( Hash )
			ret = {}
			var.each() do |key, value|
				ret[key] = decode_htmlentities( value )
			end
			return ret
		else
			return var
		end
	end

	def Strings.cleanup_lyrics( lyrics )

		lyrics = HTMLEntities.decode( lyrics )

		prev_line = ""
		lines = []

		lyrics.split( /\r\n|\n|\r/ ).each do |line|

			# remove unnecesary spaces
			line.tr_s!( "\t ", " " )
			line.strip!()

			# quotes and double quotes
			line.gsub!( /`|´|’|‘|’|/, "'" )
			line.gsub!( /''|&quot;|«|»|„|”||/, "\"" )

			# suspensive points
			line.gsub!( /…+/, "..." )
			line.gsub!( /[,;]?\.{2,}/, "..." )

			# add space after "?", "!", ",", ";", ":", ".", ")" and "]" if not present
			line.gsub!( /([^\.]?[\?!,;:\.\)\]])([^ "'<])/, "\\1 \\2" )

			# remove spaces after "¿", "¡", "(" and ")"
			line.gsub!( /([¿¡\(\[]) /, "\\1" )

			# remove spaces before "?", "!", ",", ";", ":", ".", ")" and "]"
			line.gsub!( /\ ([\?!,;:\.\)\]])/, "\\1" )

			# remove space after ... at the beginning of sentence
			line.gsub!( /^\.\.\. /, "..." )

			# remove single points at end of sentence
			line.gsub!( /([^\.])\.$/, "\\1" )

			# remove commas and semicolons at end of sentence
			line.gsub!( /[,;]$/, "" )

			# fix english I pronoun capitalization
			line.gsub!( /([ "'\(\[])i([\ '",;:\.\?!\]\)]|$)/, "\\1I\\2" )

			# remove spaces after " or ' at the begin of sentence of before them when at the end
			line.sub!( /^(["']) /, "\\1" )
			line.sub!( /\ (["'])$/, "\\1" )

			# capitalize first alfabet character of the line
			Strings.capitalize!( line )

			# no more than one empty line at the time
			if ! line.empty? || ! prev_line.empty?
				lines << line
				prev_line = line
			end
		end

		if lines.length > 0 && lines[lines.length-1].empty?
			lines.delete_at( lines.length-1 )
		end

		return lines.join( "\n" )
	end

	def Strings.cleanup_lyrics!( lyrics )
		return lyrics.replace( Strings.cleanup_lyrics( lyrics ) )
	end

	def Strings.cleanup_artist( artist, title )
		artist = artist.strip()
		if artist != ""
			if (md = /[ \(\[](ft\.|ft |feat\.|feat |featuring ) *([^\)\]]+)[\)\]]? *$/i.match( title.to_s() ))
				artist << " feat. " << md[2]
			else
				artist.gsub!( /[ \(\[](ft\.|ft |feat\.|feat |featuring ) *([^\)\]]+)[\)\]]? *$/i, " feat. \\2" )
			end
		end
		return artist
	end

	def Strings.cleanup_title( title )
		title = title.gsub( /[ \(\[](ft\.|ft |feat\.|feat |featuring ) *([^\)\]]+)[\)\]]? *$/i, "" )
		title.strip!()
		return title
	end

	def Strings.utf82latin1( text )
		begin
			return text.unpack( "U*" ).pack( "C*" )
		rescue Exception
			$stderr << "warning: conversion from UTF-8 to Latin1 failed\n"
			return text
		end
	end

	def Strings.latin12utf8( text )
		begin
			return text.unpack( "C*" ).pack( "U*" )
		rescue Exception
			$stderr << "warning: conversion from Latin1 to UTF-8 failed\n"
			return text
		end
	end

	def Strings.scramble( text )
		text = text.to_s()
		2.times() do
			chars = text.unpack( "U*" ).reverse()
			chars.size.times() { |idx| chars[idx] = (chars[idx] + idx + 1) }
			text = chars.collect() { |c| c.to_s }.join( ":" )
		end
		return text
	end

	def Strings.scramble!( text )
		return text.replace( Strings.scramble( text ) )
	end

	def Strings.descramble( text )
		text = text.to_s()
		2.times() do
			chars = text.split( ":" ).collect() { |c| c.to_i }
			chars.size.times() { |idx| chars[idx] = (chars[idx] - idx - 1) }
			text = chars.reverse().pack( "U*" )
		end
		return text
	end

	def Strings.descramble!( text )
		return text.replace( Strings.descramble( text ) )
	end

end

