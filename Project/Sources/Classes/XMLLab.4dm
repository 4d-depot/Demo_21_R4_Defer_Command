/*  Produces the sample XML files consumed by the two report builders.

	A scenario injects one defect so that a given exit point of the builders
	is reached. The XML attributes use single quotes on purpose, so the 4D
	string literals stay readable.
*/

property folder : 4D.Folder

singleton Class constructor()
	This.folder:=Folder(fk logs folder).folder("defer_demo")

Function get configFile() : 4D.File
	return This.folder.file("config.xml")

Function get catalogFile() : 4D.File
	return This.folder.file("catalog.xml")

Function get ordersFile() : 4D.File
	return This.folder.file("orders.xml")

Function get templateFile() : 4D.File
	return This.folder.file("template.xml")

Function get outputFile() : 4D.File
	return This.folder.file("report.xml")

Function prepare($scenario : Text)
	If (Not(This.folder.exists))
		This.folder.create()
	End if
	This.configFile.setText(This._config())
	This.catalogFile.setText(This._catalog($scenario))
	This.ordersFile.setText(This._orders($scenario))
	This.templateFile.setText(This._template($scenario))
	If (This.outputFile.exists)
		This.outputFile.delete()
	End if

Function _config() : Text
	var $xml : Collection:=[]
	$xml.push("<?xml version='1.0' encoding='UTF-8'?>")
	$xml.push("<config>")
	$xml.push("  <export format='xml' currency='EUR'/>")
	$xml.push("  <catalog version='2.1'/>")
	$xml.push("</config>")
	return $xml.join(Char(Carriage return))

Function _catalog($scenario : Text) : Text
	var $version : Text:="2.1"
	If ($scenario="catalogVersion")
		$version:="1.0"
	End if
	var $xml : Collection:=[]
	$xml.push("<?xml version='1.0' encoding='UTF-8'?>")
	$xml.push("<catalog version='"+$version+"'>")
	$xml.push("  <product ref='P-100' label='Keyboard' price='49.00'/>")
	$xml.push("  <product ref='P-200' label='Mouse' price='25.50'/>")
	$xml.push("  <product ref='P-300' label='Monitor' price='189.90'/>")
	$xml.push("</catalog>")
	return $xml.join(Char(Carriage return))

Function _orders($scenario : Text) : Text
	var $secondLine : Text:="P-300"
	If ($scenario="unknownProduct")
		$secondLine:="P-999"
	End if
	var $xml : Collection:=[]
	$xml.push("<?xml version='1.0' encoding='UTF-8'?>")
	$xml.push("<orders>")
	$xml.push("  <order id='A-001' customer='ACME'>")
	$xml.push("    <line ref='P-100' qty='2'/>")
	$xml.push("    <line ref='"+$secondLine+"' qty='1'/>")
	$xml.push("  </order>")
	$xml.push("  <order id='A-002' customer='Globex'>")
	$xml.push("    <line ref='P-200' qty='4'/>")
	$xml.push("  </order>")
	$xml.push("</orders>")
	return $xml.join(Char(Carriage return))

Function _template($scenario : Text) : Text
	var $xml : Collection:=[]
	$xml.push("<?xml version='1.0' encoding='UTF-8'?>")
	$xml.push("<report>")
	$xml.push("  <title>Consolidated orders</title>")
	If ($scenario#"templatePlaceholder")
		$xml.push("  <rows/>")
	End if
	$xml.push("</report>")
	return $xml.join(Char(Carriage return))
