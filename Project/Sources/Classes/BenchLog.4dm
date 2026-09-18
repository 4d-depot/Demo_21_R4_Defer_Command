/*  Collects what the benchmarks report.

	"started" counts the measures that were opened, "recorded" the ones that
	were actually closed. Any gap between the two is a benchmark that will
	never appear in the profile.
*/

property started : Integer
property recorded : Integer
property entries : Collection

singleton Class constructor()
	This.reset()

Function reset()
	This.started:=0
	This.recorded:=0
	This.entries:=[]

Function opened($label : Text)
	This.started:=This.started+1

Function closed($label : Text; $ms : Integer)
	This.recorded:=This.recorded+1
	var $entry : Object:=This.entries.query("label = :1"; $label).first()
	If ($entry=Null)
		$entry:={label: $label; calls: 0; totalMs: 0}
		This.entries.push($entry)
	End if
	$entry.calls:=$entry.calls+1
	$entry.totalMs:=$entry.totalMs+$ms

Function get lost() : Integer
	return This.started-This.recorded
