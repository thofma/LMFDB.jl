struct And
  a
  b
end

Base.:&(a::Function, b::Function) = And(a, b)

struct Or
  a
  b
end

Base.:|(a::Function, b::Function) = Or(a, b)


#            - ``$contains`` -- for json columns, the given value should be a subset of the column.
#            - ``$notcontains`` -- for json columns, the column must not contain any entry of the given value (which should be iterable)
#            - ``$containedin`` -- for json columns, the column should be a subset of the given list
#            - ``$overlaps`` -- the column should overlap the given array
#            - ``$exists`` -- if True, require not null; if False, require null.
#            - ``$startswith`` -- for text columns, matches strings that start with the given string.
#            - ``$like`` -- for text columns, matches strings according to the LIKE operand in SQL.
#            - ``$ilike`` -- for text columns, matches strings according to the ILIKE, the case-insensitive version of LIKE in PostgreSQL.
#            - ``$regex`` -- for text columns, matches the given regex expression supported by PostgresSQL
#            - ``$raw`` -- a string to be inserted as SQL after filtering against SQL injection

for ex in [(:(Base.Fix2{typeof(==)}), :("="), :(_prepare_for_lookup(t.x))),
           (:(Base.Fix2{typeof(<=)}), :("<="), :(_prepare_for_lookup(t.x))),
           (:(Base.Fix2{typeof(<)}), :("<"), :(_prepare_for_lookup(t.x))),
           (:(Base.Fix2{typeof(>=)}), :(">="), :(_prepare_for_lookup(t.x))),
           (:(Base.Fix2{typeof(>)}), :(">"), :(_prepare_for_lookup(t.x))),
           (:(Base.Fix2{typeof(!=)}), :("!="), :(_prepare_for_lookup(t.x))),
           (:(Base.Fix2{typeof(in)}), :("in"), :(_prepare_for_lookup(t.x)...)),
           (:(Base.Fix2{typeof(startswith)}), :("starts_with"), :(_prepare_for_lookup(t.x))), # David uses "like"?
          ]
  @eval function create_fun2(s::Symbol, t::$(ex[1]))
    Fun.$(ex[2])(Get(s), $(ex[3]))
  end
end

function create_fun2(s::Symbol, c::Base.ComposedFunction{typeof(!)})
  return Fun.not(create_fun2(s, c.inner))
end

function create_fun2(s::Symbol, c::And)
  return Fun.and(create_fun2(s, c.a), create_fun2(s, c.b))
end

function create_fun2(s::Symbol, c::Or)
  return Fun.or(create_fun2(s, c.a), create_fun2(s, c.b))
end

################################################################################
#
#  Conversions
#
################################################################################

_prepare_for_lookup(x) = x

function _prepare_for_lookup(x::Rational{<:Integer})
  return _stringify_list([Decimal(BigInt(numerator(x))), Decimal((BigInt(denominator(x))))])
end

function _stringify_list(a::Vector)
  return "{" * join(a, ",") * "}"
end

function _create_where(kw)
  r = []
  for (k, v) in kw
    # Some special case to allow rank = 2 instead of rank = ==(2)
    if v isa Number || v isa String
      v = ==(v)
    end
    push!(r, create_fun2(k, v))
  end
  return Where(Fun.and(r...))
end

function search(db::LMFDBConnection, tname::String; limit = Inf, kw...)
  @assert tname in db.table_names
  q = From(tname) |> 
      _create_where(kw)
  if limit != Inf
    q = q |> Limit(1:limit)
  end
  rowtable(DBInterface.execute(db.conn, q))
end
