-- Author      : Kurapica
-- Create Date : 2015/09/14
-- ChangeLog   :

Module "System.Serialization.StringFormatProvider" "1.0.0"

namespace "System.Serialization"

import "System.Reflector"

-----------------------------------
-- Serialize
-----------------------------------
do
	_Cache = setmetatable({}, {__call = function(self, key) if key then wipe(key) tinsert(self, key) else return tremove(self) or {} end end })

	function SerializeSimpleData(data)
		local dtType = type(data)

		if dtType == "string" then
			return strformat("%q", data)
		elseif dtType == "number" or dtType == "boolean" then
			return tostring(data)
		elseif dtType == "userdata" and GetNameSpaceType(data) then
			return strformat("%q", tostring(data))
		end
	end

	function SerializeDataWithWriteNoIndent(data, write)
		write("{")

		local field = Serialization.ObjectTypeField
		local val = data[field]
		if val then
			data[field] = nil

			if next(data) then
				write(strformat("%s=%q,", field, tostring(val)))
			else
				write(strformat("%s=%q", field, tostring(val)))
			end
		end

		local k, v = next(data)
		local nk, nv

		while k do
			nk, nv = next(data, k)

			if type(k) == "number" then k = strformat("[%s]", k) end
			if type(v) == "table" then
				write(strformat("%s=", k))
				SerializeDataWithWriteNoIndent(v, write)
				if nk then write(",") end
			else
				if nk then
					write(strformat("%s=%s,", k, SerializeSimpleData(v)))
				else
					write(strformat("%s=%s", k, SerializeSimpleData(v)))
				end
			end

			k, v = nk, nv
		end

		write("}")
	end

	function SerializeDataWithWrite(data, write, indentChar, preIndentChar, lineBreak)
		write("{" .. lineBreak)

		local subIndentChar = preIndentChar .. indentChar

		local field = Serialization.ObjectTypeField
		local val = data[field]
		if val then
			data[field] = nil

			if next(data) then
				write(strformat("%s%s = %q,%s", subIndentChar, field, tostring(val), lineBreak))
			else
				write(strformat("%s%s = %q%s", subIndentChar, field, tostring(val), lineBreak))
			end
		end

		local k, v = next(data)
		local nk, nv

		while k do
			nk, nv = next(data, k)

			if type(k) == "number" then k = strformat("[%s]", k) end
			if type(v) == "table" then
				write(strformat("%s%s = ", subIndentChar, k))
				SerializeDataWithWrite(v, write, indentChar, subIndentChar, lineBreak)
				if nk then
					write("," .. lineBreak)
				else
					write(lineBreak)
				end
			else
				if nk then
					write(strformat("%s%s = %s,%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
				else
					write(strformat("%s%s = %s%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
				end
			end

			k, v = nk, nv
		end

		write(preIndentChar .. "}")
	end

	function SerializeDataWithWriterNoIndent(data, write, object)
		write(object, "{")

		local field = Serialization.ObjectTypeField
		local val = data[field]
		if val then
			data[field] = nil

			if next(data) then
				write(object, strformat("%s=%q,", field, tostring(val)))
			else
				write(object, strformat("%s=%q", field, tostring(val)))
			end
		end

		local k, v = next(data)
		local nk, nv

		while k do
			nk, nv = next(data, k)

			if type(k) == "number" then k = strformat("[%s]", k) end
			if type(v) == "table" then
				write(object, strformat("%s=", k))
				SerializeDataWithWriterNoIndent(v, write, object)
				if nk then write(object, ",") end
			else
				if nk then
					write(object, strformat("%s=%s,", k, SerializeSimpleData(v)))
				else
					write(object, strformat("%s=%s", k, SerializeSimpleData(v)))
				end
			end

			k, v = nk, nv
		end

		write(object, "}")
	end

	function SerializeDataWithWriter(data, write, object, indentChar, preIndentChar, lineBreak)
		write(object, "{" .. lineBreak)

		local subIndentChar = preIndentChar .. indentChar

		local field = Serialization.ObjectTypeField
		local val = data[field]
		if val then
			data[field] = nil

			if next(data) then
				write(object, strformat("%s%s = %q,%s", subIndentChar, field, tostring(val), lineBreak))
			else
				write(object, strformat("%s%s = %q%s", subIndentChar, field, tostring(val), lineBreak))
			end
		end

		local k, v = next(data)
		local nk, nv

		while k do
			nk, nv = next(data, k)

			if type(k) == "number" then k = strformat("[%s]", k) end
			if type(v) == "table" then
				write(object, strformat("%s%s = ", subIndentChar, k))
				SerializeDataWithWriter(v, write, object, indentChar, subIndentChar, lineBreak)
				if nk then
					write(object, "," .. lineBreak)
				else
					write(object, lineBreak)
				end
			else
				if nk then
					write(object, strformat("%s%s = %s,%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
				else
					write(object, strformat("%s%s = %s%s", subIndentChar, k, SerializeSimpleData(v), lineBreak))
				end
			end

			k, v = nk, nv
		end

		write(object, preIndentChar .. "}")
	end
end

__Doc__ [[Serialization format provider for string]]
class "StringFormatProvider" (function(_ENV)
	inherit "FormatProvider"

	-----------------------------------
	-- Property
	-----------------------------------
	__Doc__[[Whether using indented format, default false]]
	property "Indent" { Type = Boolean }

	__Doc__[[The line break, default '\n']]
	property "LineBreak" { Type = String, Default = "\n" }

	__Doc__[[The char used as the indented character, default '\t']]
	property "IndentChar" { Type = String, Default = "\t" }

	-----------------------------------
	-- Method
	-----------------------------------
	__Arguments__{ Any }
	function Serialize(self, data)
		if type(data) == "table" then
			local cache = _Cache()

			if self.Indent then
				SerializeDataWithWriter(data, tinsert, cache, self.IndentChar, "", self.LineBreak)
			else
				SerializeDataWithWriterNoIndent(data, tinsert, cache)
			end

			local ret = tblconcat(cache)

			_Cache(cache)

			return ret
		else
			return SerializeSimpleData(data)
		end
	end

	__Arguments__{ Any, Function }
	function Serialize(self, data, write)
		if type(data) == "table" then
			if self.Indent then
				SerializeDataWithWrite(data, write, self.IndentChar, "", self.LineBreak)
			else
				SerializeDataWithWriteNoIndent(data, write)
			end
		else
			write(SerializeSimpleData(data))
		end
	end

	__Arguments__{ Any, System.Text.TextWriter }
	function Serialize(self, data, writer)
		if type(data) == "table" then
			if self.Indent then
				SerializeDataWithWriter(data, writer.Write, writer, self.IndentChar, "", self.LineBreak)
			else
				SerializeDataWithWriterNoIndent(data, writer.Write, writer)
			end
		else
			writer:Write(SerializeSimpleData(data))
		end
		writer:Flush()
	end

	__Doc__[[Deserialize the data to common lua data.]]
	__Arguments__{ Any }
	function Deserialize(self, data)
		return loadstring("return " .. data)()
	end

	__Arguments__{ System.Text.TextReader }
	function Deserialize(self, reader)
		local data = reader:ReadToEnd()

		if data then
			return loadstring("return " .. data)()
		end
	end
end)