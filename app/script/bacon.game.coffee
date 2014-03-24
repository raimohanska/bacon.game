Bacon = require("baconjs")
$ = require("jquery")
_ = require("lodash")

$.fn.asEventStream = Bacon.$.asEventStream

Bacon.Observable :: withTimestamp = ({ relative, precision } = { precision: 1 }) ->
  offset = if relative then new Date().getTime() else 0
  @flatMap (value) -> { value, timestamp: Math.floor((new Date().getTime() - offset) / precision) }

assignments = [{
  description: "output value 1 immediately",
  example: "function answer() { return Bacon.once(1) }",
  template: "function answer() { return Bacon.never() }"
  inputs: -> []
}]

presentAssignment = (assignment) ->
  $("#assignment .description").text(assignment.description)
  #codeP = b$.textFieldValue($("#assignment .code"), assignment.template)
  $code = $("#assignment .code")
  $code.val(assignment.template)
  codeP = $code.asEventStream("input").merge(Bacon.once()).toProperty().map(-> $code.val())

  resultE = codeP.sampledBy($("#assignment .run").asEventStream("click").doAction(".preventDefault")).flatMap (code) ->
    evaluateAssignment assignment, code

  resultE.map((x) -> if x then "Success!" else "FAIL").assign($("#assignment .result"), "text")

evaluateAssignment = (assignment, code) ->
  actual = evalCode(code)(assignment.inputs() ...)
  expected = evalCode(assignment.example)(assignment.inputs() ...)

  actualValues = timestampedValues actual
  expectedValues = timestampedValues expected

  comparableValues = Bacon.combineTemplate
    actual: foldValues(actualValues)
    expected: foldValues(expectedValues)

  success = comparableValues.map ({actual, expected}) ->
    _.isEqual(actual, expected)

  success

timestampedValues = (src) ->
  src.withTimestamp({relative:true, precision: 100})

foldValues = (src) ->
  src.fold([], (values, value) -> values.concat(value))

collectAndVisualize = (src, values, desc) -> 
  src.withTimestamp({relative:true, precision: 100}).onValue (value) ->
    values.push(value)
    console.log(desc, value)

evalCode = (code) -> eval("(" + code + ")")

presentAssignment assignments[0]
