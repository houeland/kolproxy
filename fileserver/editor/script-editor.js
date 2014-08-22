"use strict";

var ScriptEditor = {}

function build_toolbox() {
	var toolbox_types = ["block_one", "block_two"]
	var toolbox = ""
	for (var i = 0; i < toolbox_types.length; i += 1) {
		toolbox += "	<block type=\"" + toolbox_types[i] + "\"></block>"
	}
	var extra = "	<block type=\"block_one\"><value name=\"TEXT\"><block type=\"block_two\"></block></value></block>"
	return "<xml>" + toolbox + extra + "</xml>"
}

ScriptEditor.onload = function() {
	Blockly.inject(document.getElementById("blocklyDiv"), { path: "./", toolbox: build_toolbox() })
	Blockly.addChangeListener(ScriptEditor.onchange)
}

window.addEventListener("load", ScriptEditor.onload)

ScriptEditor.onchange = function() {
	var code = Blockly.EditorScript.workspaceToCode()
	document.title = code
}

Blockly.EditorScript = new Blockly.Generator('EditorScript')

Blockly.Blocks["block_one"] = {
	init: function() {
		this.setColour(100)
		this.appendValueInput("VALUE").appendField("one:")
		this.appendValueInput("TEXT").appendField("txt:")
	}
}

Blockly.EditorScript["block_one"] = function(block) {
	var code_value = Blockly.EditorScript.valueToCode(block, "VALUE", Blockly.EditorScript.ORDER_ATOMIC) || "?VALUE?"
	var code_text = Blockly.EditorScript.valueToCode(block, "TEXT", Blockly.EditorScript.ORDER_ATOMIC) || "?TEXT?"
	return "block_one [" + code_value + " | " + code_text + "]"
}

Blockly.Blocks["block_two"] = {
	init: function() {
		this.setColour(200)
		this.appendDummyInput().appendField("errata")
		this.setOutput(true, "Number")
	}
}

Blockly.EditorScript["block_two"] = function(block) {
	return ["block_two_errata", Blockly.EditorScript.ORDER_NONE]
}

Blockly.EditorScript.ORDER_ATOMIC = 0
Blockly.EditorScript.ORDER_NONE = 99

Blockly.EditorScript.init = function() {}

Blockly.EditorScript.finish = function(code) { return code }

Blockly.EditorScript.scrubNakedValue = function(line) { return "" }

//Blockly.EditorScript.quote_ = function(string) { return '(quot:' + string + ')' }

Blockly.EditorScript.scrub_ = function(block, code) { return code + this.blockToCode(block.nextConnection && block.nextConnection.targetBlock()) }
