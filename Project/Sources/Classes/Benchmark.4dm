/*  A one-shot benchmark: creating it starts the measure, stopping it records it.

	This is the kind of helper a developer drops at the top of a method to
	measure it — and then has to close on every single exit path.
*/

property label : Text
property startedAt : Integer
property running : Boolean

Class constructor($label : Text)
	This.label:=$label
	This.startedAt:=Milliseconds
	This.running:=True
	cs.BenchLog.me.opened($label)

Function stop()
	If (Not(This.running))
		return
	End if
	This.running:=False
	cs.BenchLog.me.closed(This.label; Milliseconds-This.startedAt)
