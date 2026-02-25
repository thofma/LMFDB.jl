function _lattice_from_record(record::NamedTuple)
  r = Int(record[:rank])
  G = matrix(ZZ, r, r, record[:gram])
  L = integer_lattice(;gram = G)
  return L
end

function Hecke.integer_lattice(db, label::String)
  res = LMFDBLite.search(db, "lat_lattices_new"; label = ==(label))
  @assert length(res) <= 1
  if length(res) == 0
    error("label does not exist")
  end
  return _lattice_from_record(res[1])
end

function integer_lattices(db; kw...)
  res = LMFDBLite.search(db, "lat_lattices_new"; kw...)
  return _lattice_from_record.(res)
end
