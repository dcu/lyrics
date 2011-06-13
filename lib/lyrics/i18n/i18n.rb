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

require File.expand_path( File.dirname( __FILE__ ) + "/../utils/strings" )
require "iconv"

module I18n

	@@DEFAULT_LANG = "en"
	@@DEFAULT_ENCODING = "UTF-8"

	@@loaded = false
	@@texts = {}
	@@files_prefix = File.expand_path( File.dirname( __FILE__ ) )

	def I18n.get( key, *args )
		I18n.reload() if ! @@loaded
		ret = @@texts[key]
		return key if ret == nil
		if args
			arg_idx = 1
			args.each() do |arg|
				ret = ret.gsub( "%#{arg_idx}", arg.to_s() )
				arg_idx += 1
			end
		end
		return ret
	end

	def I18n.reload()
		@@texts = {}
		I18n.load_translation( "en" ) # the default and reference meaning of keys
		language = I18n.get_local_language()
		I18n.load_translation( language ) if language != "en"
		@@loaded = true
	end


	def I18n.get_messages_locale()
		locale = `locale`

		# LC_ALL overrides the values of all the other internationalization variables if set to a non-empty string value
		if (md = /LC_ALL="?([^\n"]*)"?/.match( locale ))
			return md[1] if ! Strings.empty?( md[1] )
		end

		# if set, use LC_MESSAGES
		if (md = /LC_MESSAGES="?([^\n"]*)"?/.match( locale ))
			return md[1] if ! Strings.empty?( md[1] )
		end

		# LANG provides a default value for the internationalization variables that are unset or null
		if (md = /LANG="?([^\n"]*)"?/.match( locale ))
			return md[1] if ! Strings.empty?( md[1] )
		end

		return nil
	end

	def I18n.get_local_language()
		language = I18n.get_messages_locale()
		language = ENV["LANGUAGE"].to_s().strip() if Strings.empty?( language )
		language = ENV["LANG"].to_s().strip() if Strings.empty?( language )
		return @@DEFAULT_LANG if language.empty?
		language.sub!( /_[^.]+/, "" )
		return @@DEFAULT_LANG if ! language.sub!( /\..+$/, "" )
		return language
	end

	def I18n.get_local_encoding()
		encoding = ENV["LANG"].to_s().strip()
		return @@DEFAULT_ENCODING if encoding.empty?
		return @@DEFAULT_ENCODING if ! encoding.sub!( /^.+\./, "" )
		return encoding
	end

	begin
		@@locale2utf8 = Iconv.new( I18n.get_local_encoding(), "UTF-8" )
	rescue
		@@locale2utf8 = nil
	end

	def I18n.load_translation( language )
		begin
			file = File.new( "#{@@files_prefix}/#{language}.rb", "r" )
			while ( line = file.gets )
				line = @@locale2utf8.iconv( line ) if @@locale2utf8
				if (md = /^ *([a-z\.]+) *= *(.*)$/.match( line ))
					key, value = md[1], md[2].strip()
					next if value.empty?
					@@texts[key] = value
					@@texts[key].gsub!( /\\./ ) do |m|
						char = m.slice( 1, 1 )
						if char == "\\"
							"\\"
						elsif char == "n"
							"\n"
						else
							char
						end
					end
				end
			end
			file.close()
		rescue Errno::ENOENT
			puts "translations file not found: #{language}.rb"
		end
	end

end

