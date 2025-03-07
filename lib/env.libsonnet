// This module implements a function which sorts a list of Kubernetes Pod
// environment variables based on their dependency depth.

// Find dependencies on `names` in `str`
//
// For `name` in `names`, find whether `str` contains `$(name)`
local extractDeps(names) = function(str)
  std.filter(
    function(m)
      local pat = std.format('$(%s)', m);
      std.member(str, pat),
    names,
  );


// Calculate the dependency depth for the given variable name.
//
// Expects `deps` to be a map of variable names to dependency names
local calculateDepth = function(name, deps)
  if std.length(deps[name]) == 0 then
    0
  else
    1 + std.foldl(
      function(acc, depName) std.max(acc, calculateDepth(depName, deps)),
      deps[name],
      0,
    );

local sortDeps = function(items)
  // collect valid variable names
  local names = std.map(function(m) m.name, items);
  local extractDepsWithNames = extractDeps(names);

  // collect the dependencies for each variable name, or an empty list if the
  // variable is not a plain value (e.g. for secret or field ref values)
  local deps = std.foldl(
    function(acc, i)
      local deps = if std.objectHas(i, 'value') then
        extractDepsWithNames(i.value)
      else
        [];
      acc { [i.name]: deps },
    items,
    {},
  );
  local itemsWithDepth = std.map(
    function(i) i {
      depth:: if std.objectHas(i, 'value')
      then calculateDepth(i.name, deps)
      else -1,
    },
    items,
  );
  std.sort(
    itemsWithDepth,
    function(i) i.depth,
  );

local mapEnv(name, value) =
  { name: name } + if std.isString(value)
  then { value: value }
  else
    { valueFrom: {
      [if std.objectHas(value, 'secretName') then 'secretKeyRef']: {
        name: value.secretName,
        key: value.key,
      },
      [if std.objectHas(value, 'fieldPath') then 'fieldRef']: value,
    } };

local fromObj(obj) =
  local arr = std.map(
    function(o) mapEnv(o.key, o.value),
    std.objectKeysValues(obj)
  );
  sortDeps(arr);

{
  fromObj: fromObj,
}
