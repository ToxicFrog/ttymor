local reprs = {}

local function _rawrepr(V, handlers, refs, indent)
  local handler = handlers[type(V)]
  if handler then
    return handler(V, handlers, refs, indent)
  end
  return nil
end

local function repr_with(V, handlers, refs, indent)
  local mt = getmetatable(V)
  if mt and mt.__repr then
    return mt.__repr(V, handlers, refs, indent)
  end
  return _rawrepr(V, handlers, refs, indent)
end

-- Special repr function for keys used in a table literal.
local function repr_key(V, ...)
  if type(V) == 'string' and V:match("^[%a_][%w_]*$") then
    return V
  end
  return '['..repr_with(V, ...)..']'
end

function _repr(V, handlers, refs, indent)
  return repr_with(V, handlers or reprs, refs or {}, indent or '')
end

reprs.boolean = tostring
reprs.number = tostring
reprs["nil"] = tostring

-- No support for coroutines or userdata
--reprs.thread = error
--reprs.userdata = error
--reprs.function = error

function reprs.string(S)
  return ("%q"):format(S)
end

function reprs.table(T, handlers, refs, indent)
  if refs[T] then
    return nil
  end

  refs[T] = true
  local new_indent = indent.."  "
  local S = {'{'}

  local keys = {}
  for i,v in ipairs(T) do
    keys[v] = true
    v = repr_with(v, handlers, refs, new_indent)
    if v then
      table.insert(S, "%s%s;" % { new_indent, v })
    else
      table.insert(S, "%snil;" % new_indent)
    end
  end

  for k,v in pairs(T) do
    if not keys[v] then
      k,v = repr_key(k, handlers, refs, indent), repr_with(v, handlers, refs, new_indent)
      if k and v then
        table.insert(S, string.format("%s%s = %s;", new_indent, k, v))
      end
    end
  end

  if #S == 1 then
    return '{}'
  end
  table.insert(S, indent..'}')
  return table.concat(S, "\n")
end

-- set globals
repr = _repr
rawrepr = _rawrepr
