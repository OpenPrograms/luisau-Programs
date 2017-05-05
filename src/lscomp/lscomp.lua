local component = require ("component")
function printComponentList ()
  for k, v in component.list() do
    print ("  ".. v, k)
  end
  print()
end

printComponentList ()