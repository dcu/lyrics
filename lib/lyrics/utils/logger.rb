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

class Logger

	def initialize( file_path, truncate_to_lines=-1 )
		@file_path = file_path
		@tabulation = nil
		@tabulation_base = "   ".freeze()
		@tabulation_level = 0
		@skip_first_line_tabulation = false
		truncate( truncate_to_lines ) if truncate_to_lines >= 0
	end

	def finalize() # TODO revise implementation
	end

	def get_file_path()
		return @file_path
	end

	def set_file_path( file_path )
		if @file_path != file_path
			File.delete( @file_path ) if File.exist?( @file_path ) && ! File.directory?( @file_path )
			@file_path = file_path.clone().freeze()
		end
	end

	def truncate( max_lines )
		begin
			file = File.new( @file_path, File::RDONLY )
		rescue Errno::ENOENT
			file = File.new( @file_path, File::CREAT|File::TRUNC )
		end
		lines = file.read().split( "\n" )
		file.close()
		offset = lines.size() - max_lines
		if offset > 0
			file = File.new( @file_path, File::CREAT|File::TRUNC|File::WRONLY )
			max_lines.times() do |index|
				line = lines[offset + index]
				break if ! line
				file.write( line )
				file.write( "\n" )
			end
			file.close()
		end
	end

	def reset()
		output = File.new( @file_path, File::CREAT|File::TRUNC )
		output.close()
	end

	def log( msg, new_lines=1 )
		output = File.new( @file_path, File::CREAT|File::APPEND|File::WRONLY )
		if @tabulation
			output.write( @tabulation ) if ! @skip_first_line_tabulation
			output.write( msg.gsub( "\n", "\n#{@tabulation}" ) )
			@skip_first_line_tabulation = new_lines <= 0
		else
			output.write( msg )
		end
		new_lines.times() { output.write( "\n" ) }
		output.close()
	end

	def get_tabulation_base()
		return @tabulation_base
	end

	def set_tabulation_base( tabulation_base )
		if @tabulation_base != tabulation_base
			@tabulation_level = tabulation_base.clone().freeze()
			if level <= 0
				@tabulation = nil
			else
				@tabulation = ""
				level.times() { @tabulation << @tabulation_base }
			end
		end
	end

	def get_tabulation_level()
		return @tabulation_level
	end

	def set_tabulation_level( level )
		if @tabulation_level != level
			@tabulation_level = level
			if level <= 0
				@tabulation = nil
			else
				@tabulation = ""
				level.times() { @tabulation << @tabulation_base }
			end
		end
	end

	def increase_tabulation_level()
		set_tabulation_level( @tabulation_level + 1 )
	end

	def decrease_tabulation_level()
		set_tabulation_level( @tabulation_level - 1 )
	end

end
