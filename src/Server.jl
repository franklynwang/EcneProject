
# Simple REST API via Genie for acepting verification requests

using Genie, Genie.Router, Genie.Requests, Genie.Renderer.Json, Genie.Cache
import R1CSConstraintSolver: solveWithTrustedFunctions

route("/verify", method = POST) do
  @show jsonpayload()
  @show rawpayload()

  @show jsonpayload()["r1cs"]
  @show jsonpayload()["sym"]
  @show jsonpayload()["id"]

  dict = Dict("result" => "empty", "constraints" => ["empty"])

  try
    solveWithTrustedFunctions(jsonpayload()["r1cs"], jsonpayload()["sym"], jsonpayload()["id"], dict)
  catch e
    println("Error while running solveWithTrustedFunctions", e)
  end

  println(dict)
  #dict["output"] = String("asdfsadfasdfasd asdf asadf")

  #json("Hello $(jsonpayload()["r1cs"])")
  json(dict)

end

Genie.startup(async = false)
#async = false)
#up()

