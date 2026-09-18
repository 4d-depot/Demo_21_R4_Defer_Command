/*  Side-by-side comparison of two writing styles, on two examples.
	Both code panes are read from the real .4dm source files.
*/

property examples : Object
property exampleKeys : Collection
property scenarios : Object
property keys : Collection
property subtitle : Text
property legacyAll : Collection
property deferAll : Collection
property legacyLines : Collection
property deferLines : Collection
property metricsLegacy : Text
property metricsDefer : Text
property resultMessage : Text
property cleanupOnly : Boolean

Class constructor()
	This.examples:={values: [\
		"XML — closing 5 document references"; \
		"Benchmark — closing the measure"\
		]; index: 0}
	This.exampleKeys:=["xml"; "bench"]
	This.cleanupOnly:=False
	This._loadExample()

//MARK: - Form objects event handlers

Function dropExampleEventHandler($formEventCode : Integer)
	Case of
		: ($formEventCode=On Data Change)
			This._loadExample()
	End case

Function btnRunEventHandler($formEventCode : Integer)
	Case of
		: ($formEventCode=On Clicked)
			This._runBoth()
	End case

Function chkCleanupEventHandler($formEventCode : Integer)
	Case of
		: ($formEventCode=On Clicked)
			This._applyFilter()
	End case

//MARK: - Examples

Function get isBenchmark() : Boolean
	return (This.exampleKeys[This.examples.index]="bench")

Function _loadExample()
	var $noun : Text
	If (This.isBenchmark)
		This.subtitle:="1 benchmark · 12 exit points — a measure that has to be closed on every single path."
		This.scenarios:={values: [\
			"Nominal — order priced (exit 12)"; \
			"Customer is blocked (exit 5)"; \
			"Unknown product in a line (exit 9)"; \
			"Unsupported currency, error caught (exit 7)"; \
			"Conflicting discounts (exit 11) — the measure is lost"\
			]; index: 0}
		This.keys:=["nominal"; "blockedCustomer"; "unknownProduct"; "badCurrency"; "discountConflict"]
		This.legacyAll:=This._loadSource("PricingEngineLegacy")
		This.deferAll:=This._loadSource("PricingEngineDefer")
		$noun:="benchmark closings"
	Else
		This.subtitle:="5 XML document references · 11 exit points · 2 nested loops."
		This.scenarios:={values: [\
			"Nominal — the report is produced (exit 11)"; \
			"Catalog version mismatch (exit 4)"; \
			"Template placeholder missing (exit 8)"; \
			"Unknown product in an order (exit 9)"\
			]; index: 0}
		This.keys:=["nominal"; "catalogVersion"; "templatePlaceholder"; "unknownProduct"]
		This.legacyAll:=This._loadSource("XMLReportBuilderLegacy")
		This.deferAll:=This._loadSource("XMLReportBuilderDefer")
		$noun:="clean-up statements"
	End if
	This.resultMessage:="press Run both to execute the two versions"
	This.metricsLegacy:=This._metrics(This.legacyAll; $noun)
	This.metricsDefer:=This._metrics(This.deferAll; $noun)
	This._applyFilter()

//MARK: - Demo driver

Function _runBoth()
	If (This.isBenchmark)
		This._runBenchmark()
	Else
		This._runXML()
	End if

Function _runXML()
	var $scenario : Text:=This.keys[This.scenarios.index]
	var $legacy : Object:=cs.XMLReportBuilderLegacy.me.build($scenario)
	var $defer : Object:=cs.XMLReportBuilderDefer.me.build($scenario)

	If (($legacy.exit=$defer.exit) && ($legacy.xml=$defer.xml) && ($legacy.message=$defer.message))
		This.resultMessage:="Exit "+String($defer.exit)+" on both sides — "+$defer.message
	Else
		This.resultMessage:="The two versions diverge!"
	End if
	This._spotExit($defer.exit)

Function _runBenchmark()
	var $scenario : Text:=This.keys[This.scenarios.index]
	var $bench : cs.BenchLog:=cs.BenchLog.me

	$bench.reset()
	var $legacy : Object:=cs.PricingEngineLegacy.me.compute($scenario)
	var $legacyStarted : Integer:=$bench.started
	var $legacyRecorded : Integer:=$bench.recorded

	$bench.reset()
	var $defer : Object:=cs.PricingEngineDefer.me.compute($scenario)
	var $deferStarted : Integer:=$bench.started
	var $deferRecorded : Integer:=$bench.recorded

	This.resultMessage:="Exit "+String($defer.exit)+" — measures recorded: " \
		+String($legacyRecorded)+"/"+String($legacyStarted)+" without defer,  " \
		+String($deferRecorded)+"/"+String($deferStarted)+" with defer"
	This._spotExit($defer.exit)

Function _spotExit($exit : Integer)
	This._selectExitRow("lbLegacy"; This.legacyLines; $exit)
	This._selectExitRow("lbDefer"; This.deferLines; $exit)

//MARK: - Source code panes

Function _loadSource($className : Text) : Collection
	var $lines : Collection:=[]
	var $file : 4D.File:=File("/SOURCES/Classes/"+$className+".4dm")
	If (Not($file.exists))
		$file:=Folder(fk database folder).file("Sources/Classes/"+$className+".4dm")
	End if
	If (Not($file.exists))
		return $lines
	End if

	var $text : Text:=$file.getText()
	$text:=Replace string($text; Char(Carriage return)+Char(Line feed); Char(Line feed))
	$text:=Replace string($text; Char(Carriage return); Char(Line feed))

	var $rawLines : Collection:=Split string($text; Char(Line feed))
	var $raw : Text
	var $num : Integer:=0
	For each ($raw; $rawLines)
		$num:=$num+1
		$lines.push(This._codeRow($num; $raw))
	End for each
	return $lines

Function _codeRow($num : Integer; $raw : Text) : Object
	var $code : Text:=Replace string($raw; Char(Tab); "    ")
	var $kind : Text:="code"
	Case of
		: (Position("!! FORGOTTEN"; $code)>0)
			$kind:="missing"
		: (Position("--- EXIT"; $code)>0)
			$kind:="exit"
		: (Position("defer("; $code)>0)
			$kind:="defer"
		: (Position("DOM CLOSE XML"; $code)>0)
			$kind:="cleanup"
		: (Position("$benchmark.stop()"; $code)>0)
			$kind:="cleanup"
		: (Position("//"; Replace string($code; " "; ""))=1)
			$kind:="comment"
	End case
	return {num: $num; code: $code; kind: $kind; meta: This._meta($kind)}

Function _meta($kind : Text) : Object
	Case of
		: ($kind="cleanup")
			return {stroke: "#C81E1E"; fontWeight: "bold"}
		: ($kind="defer")
			return {stroke: "#1A7F37"; fontWeight: "bold"}
		: ($kind="missing")
			return {stroke: "#FFFFFF"; fill: "#C81E1E"; fontWeight: "bold"}
		: ($kind="exit")
			return {stroke: "#0B63CE"; fontWeight: "bold"}
		: ($kind="comment")
			return {stroke: "#8892A4"; fontStyle: "italic"}
		Else
			return {stroke: "#1F2933"}
	End case

Function _metrics($lines : Collection; $noun : Text) : Text
	var $cleanup : Integer:=$lines.query("kind in :1"; ["cleanup"; "defer"]).length
	var $exits : Integer:=$lines.query("kind = :1"; "exit").length
	return String($lines.length)+" lines   |   "+String($exits)+" exit points   |   " \
		+String($cleanup)+" "+$noun

Function _applyFilter()
	If (This.cleanupOnly)
		This.legacyLines:=This.legacyAll.query("kind in :1"; ["cleanup"; "defer"; "exit"; "missing"])
		This.deferLines:=This.deferAll.query("kind in :1"; ["cleanup"; "defer"; "exit"; "missing"])
	Else
		This.legacyLines:=This.legacyAll
		This.deferLines:=This.deferAll
	End if

Function _selectExitRow($objectName : Text; $lines : Collection; $exit : Integer)
	var $needle : Text:="--- EXIT "+String($exit)+" "
	var $i : Integer
	For ($i; 0; $lines.length-1)
		If (Position($needle; $lines[$i].code)>0)
			LISTBOX SELECT ROW(*; $objectName; $i+1; lk replace selection)
			return
		End if
	End for
