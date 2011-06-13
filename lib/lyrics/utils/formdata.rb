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

require "cgi"

module URLEncodedFormData

	def URLEncodedFormData.prepare_query( params )
		query = params.collect { |name, value| "#{name}=#{CGI.escape( value.to_s() )}" }.join( "&" )
		header = { "Content-type" => "application/x-www-form-urlencoded" }
		return query, header
	end

end

module MultipartFormData

	@@boundary = "----------nOtA5FcjrNZuZ3TMioysxHGGCO69vA5iYysdBTL2osuNwOjcCfU7uiN"

	def MultipartFormData.text_param( name, value )
		return	"Content-Disposition: form-data; name=\"#{CGI.escape(name)}\"\r\n" \
				"\r\n" \
				"#{value}\r\n"
	end

	def MultipartFormData.file_param( name, file, mime_type, content )
		return	"Content-Disposition: form-data; name=\"#{CGI.escape(name)}\"; filename=\"#{file}\"\r\n" \
				"Content-Transfer-Encoding: binary\r\n" \
				"Content-Type: #{mime_type}\r\n" \
				"\r\n" \
				"#{content}\r\n"
	end

	def MultipartFormData.prepare_query( params )
		query = params.collect { |param| "--#{@@boundary}\r\n#{param}" }.join( "" ) + "--#{@@boundary}--"
		header = { "Content-type" => "multipart/form-data; boundary=" + @@boundary }
		return query, header
	end

end

