#(:det, :disc, :id, :level, :rank, :nplus, :is_even, :discriminant_form, :discriminant_group_invs, :conway_symbol, :label, :rep, :mass, :class_number, :adjacency_matrix, :adjacency_polynomials, :dual_conway_symbol)

function _genus_from_record(db, record::NamedTuple)
  label = record[:label]
  reps = integer_lattices(db; genus_label = ==(label))
  G = Hecke.genus(reps[1])
  set_attribute!(G, :representatives => reps)
  return G
end

function genus(db, label::String)
  res = LMFDBLite.search(db, "lat_genera"; label = ==(label))
  @assert length(res) <= 1
  if length(res) == 0
    error("label does not exist")
  end
  return _genus_from_record(db, res[1])
end

function genera(db; kw...)
  res = LMFDBLite.search(db, "lat_genera"; kw...)
  return _genus_from_record.(Ref(db), res)
end
