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

require File.expand_path( File.dirname( __FILE__ ) + "/strings" )

module ITRANS

	@@itrans_dir = File.dirname( File.expand_path(__FILE__) ) + "/../itrans"
	@@null_dev = "/dev/null"

	def ITRANS.normalize( text )
		return ITRANS.from_devanagari!( ITRANS.to_devanagari( text ) )
	end

	def ITRANS.to_devanagari!( text )
		text.replace( to_devanagari( text ) )
	end

	def ITRANS.to_devanagari( text )
		orig_pwd = Dir.pwd()
		Dir.chdir( @@itrans_dir )
		trans = `echo #{Strings.shell_quote( "#indianifm=udvng.ifm\n #indian\n#{text}\n#endindian" )} | #{@@itrans_dir}/itrans -U 2>#{@@null_dev}`
		Dir.chdir( orig_pwd )
		trans.gsub!( /%[^\n]*/, "" ) # TODO search line
		trans.strip!()
		return trans
	end

	def ITRANS.from_devanagari!( text )
		@@devanagari2itrans.each() do |devana, itrans|
			text.gsub!( devana, itrans )
		end
		@@devanagari2itrans_consonants.each() do |devana, itrans|
			# is the only symbol in the 'word' --> add an 'a' at the end:
			text.gsub!( /(^|[ ""\.:;\(\[])#{devana}([,;:?!\)\]\s]|$)/, "\\1#{itrans}a\\2" )
			# is not followed by a vocal --> add an 'a' at the end:
			text.gsub!( /#{devana}([^aeiouAEIOU,;:?!\)\]\s])/, "#{itrans}a\\1" )
			text.gsub!( devana, itrans )
		end
		return text
	end

	def ITRANS.from_devanagari( text )
		return ITRANS.from_devanagari!( String.new( text ) )
	end

	def ITRANS.unicode( codepoint )
		[codepoint].pack( "U*" )
	end

	@@devanagari2itrans = {
		ITRANS.unicode( 0x0901 ) => "",

		# vowels:
		ITRANS.unicode( 0x0905 ) => "a",
		ITRANS.unicode( 0x0906 ) => "aa", # /A
		ITRANS.unicode( 0x093E ) => "aa", # /A
		ITRANS.unicode( 0x0907 ) => "i",
		ITRANS.unicode( 0x093F ) => "i",
		ITRANS.unicode( 0x0908 ) => "ii", # /I
		ITRANS.unicode( 0x0940 ) => "ii", # /I
		ITRANS.unicode( 0x0909 ) => "u",
		ITRANS.unicode( 0x0941 ) => "u",
		ITRANS.unicode( 0x090A ) => "uu", # /U
		ITRANS.unicode( 0x0942 ) => "uu", # /U
		ITRANS.unicode( 0x090B ) => "RRi", # R^i
		ITRANS.unicode( 0x0943 ) => "RRi", # R^i
		ITRANS.unicode( 0x090C ) => "LLi", # L^i
		ITRANS.unicode( 0x0944 ) => "LLi", # L^i
		ITRANS.unicode( 0x090F ) => "e",
		ITRANS.unicode( 0x0947 ) => "e",
		ITRANS.unicode( 0x0910 ) => "ai",
		ITRANS.unicode( 0x0948 ) => "ai",
		ITRANS.unicode( 0x0913 ) => "o",
		ITRANS.unicode( 0x094B ) => "o",
		ITRANS.unicode( 0x0914 ) => "au",
		ITRANS.unicode( 0x094C ) => "au",
		# itrans irregular
		"क्ष"=> "kSh", # x / kS
		"त्र"=> "tr",
		"ज्ञ"=> "j~n", # GY / dny
		"श्र"=> "shr",
	}

	@@devanagari2itrans_consonants = {
		# gutturals:
		ITRANS.unicode( 0x0915 ) => "k",
		ITRANS.unicode( 0x0916 ) => "kh",
#		ITRANS.unicode( 0x0916 ) => ".Nkh",
		ITRANS.unicode( 0x0917 ) => "g",
		ITRANS.unicode( 0x0918 ) => "gh",
		ITRANS.unicode( 0x0918 ) => "~N",
		# palatals:
		ITRANS.unicode( 0x091A ) => "ch",
		ITRANS.unicode( 0x091B ) => "Ch",
		ITRANS.unicode( 0x091C ) => "j",
		ITRANS.unicode( 0x091D ) => "jh",
		ITRANS.unicode( 0x091E ) => "~n", # JN
		# retroflexes:
		ITRANS.unicode( 0x091F ) => "T",
		ITRANS.unicode( 0x0920 ) => "Th",
		ITRANS.unicode( 0x0921 ) => "D",
		ITRANS.unicode( 0x0922 ) => "Dh",
#		ITRANS.unicode( 0x0922 ) => ".Dh", # Rh (valid?)
		ITRANS.unicode( 0x0923 ) => "N",
		# dentals:
		ITRANS.unicode( 0x0924 ) => "t",
		ITRANS.unicode( 0x0925 ) => "th",
		ITRANS.unicode( 0x0926 ) => "d",
		ITRANS.unicode( 0x0927 ) => "dh",
		ITRANS.unicode( 0x0928 ) => "n",
		# labials:
		ITRANS.unicode( 0x092A ) => "p",
		ITRANS.unicode( 0x092B ) => "ph",
		ITRANS.unicode( 0x092C ) => "b",
		ITRANS.unicode( 0x092D ) => "bh",
		ITRANS.unicode( 0x092E ) => "m",
		# semi-vowels:
		ITRANS.unicode( 0x092F ) => "y",
		ITRANS.unicode( 0x0930 ) => "r",
		ITRANS.unicode( 0x0932 ) => "l",
		ITRANS.unicode( 0x0935 ) => "v", # w
		# sibilants:
		ITRANS.unicode( 0x0936 ) => "sh",
		ITRANS.unicode( 0x0937 ) => "Sh", # shh
		ITRANS.unicode( 0x0938 ) => "s",
		# miscellaneous:
		ITRANS.unicode( 0x0939 ) => "h",
		ITRANS.unicode( 0x0902 ) => ".n", # M / .m
		ITRANS.unicode( 0x0903 ) => "H", # .h
		ITRANS.unicode( 0x0950 ) => "OM", # AUM
		# other consonants:
		"क़" => "q",
		ITRANS.unicode( 0x0958 ) => "q",
		"ख़" => "Kh",
		"ग़" => "G",
		"ज़" => "z",
		ITRANS.unicode( 0x095B ) => "z",
		"फ़" => "f",
		"ड़" => ".D", # R
		ITRANS.unicode( 0x095C ) => ".D", # R (valid?)
		"ढ़" => ".Dh", # Rh
	}

end
