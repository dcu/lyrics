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

require "rexml/document"

module XMLHash

	def XMLHash.write( file, hash )

		begin
			read_file = nil
			read_file = file.is_a?( File ) ? file : File.new( file, "r" )
			root = REXML::Document.new( read_file ).root
		rescue Exception
			root = REXML::Document.new( "<?xml version='1.0' encoding='UTF-8' ?>" ).add_element( "settings" )
		ensure
			read_file.close() if read_file
		end

		begin
			write_file = nil
			if ( file.is_a?( File ) )
				file.reopen( file.path, "w+" )
				write_file = file
			else
				write_file = File.new( file, "w+" )
			end
			hash.each do |key, value|
				element = root.elements[key]
				element = root.add_element( key ) if ! element
				element.text = value.is_a?( Array ) ? value.join( "\n" ) : value.to_s()
				element.add_attribute( "type", value.class.name.downcase )
			end
			root.parent.write( write_file )
			write_file.flush()
			return true
		rescue Exception => e
			puts e
			puts e.backtrace
			return false
		ensure
			write_file.close() if write_file != file
		end

	end

	def XMLHash.read( file, hash, only_hash_keys=true )

		begin
			read_file = nil
			read_file = file.is_a?( File ) ? file : File.new( file, "r" )
			elements = REXML::Document.new( read_file ).root.elements
			return false if elements == nil
		rescue Exception => e
			return false
		ensure
			read_file.close() if read_file && read_file != file
		end

		requested_keys = hash.keys

		keys = hash.keys
		if ! only_hash_keys
			elements.each() do |element|
				key = element.name
				keys << key if ! keys.include?( key )
			end
		end

		read_keys = []
		keys.each() do |key|
			if elements[key]
				value = elements[key].text.to_s()
				type = elements[key].attribute( "type" ).to_s()
				if type == "array"
					hash[key] = value.split( "\n" )
				elsif ( type == "fixnum" )
					hash[key] = value.to_i()
				elsif ( type == "float" )
					hash[key] = value.to_f()
				elsif ( type == "trueclass" )
					hash[key] = true
				elsif ( type == "falseclass" )
					hash[key] = false
				else
					hash[key] = value
				end
				read_keys << key
			end
		end

		return (requested_keys - read_keys).empty?

	end

end
