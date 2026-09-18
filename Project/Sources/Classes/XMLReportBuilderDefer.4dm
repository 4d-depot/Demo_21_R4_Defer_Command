/*  Consolidated XML report — WITH defer (4D 21 R4).

	Exactly the same logic, the same five XML document references and the same
	eleven exit points. Each clean-up is written ONCE, right below the line
	that allocated the resource, and 4D runs it whatever the exit is.

	5 defer lines instead of 30 clean-up lines — and nothing to forget.
*/

singleton Class constructor()

Function build($scenario : Text) : Object
	var $lab : cs.XMLLab:=cs.XMLLab.me
	var $result : Object:={ok: False; exit: 0; message: ""; xml: ""}
	var $configRef; $catalogRef; $ordersRef; $templateRef; $reportRef : Text
	var $exportNode; $catalogNode; $orderNode; $lineNode; $productNode : Text
	var $rowsNode; $rowsRef; $rowNode : Text
	var $currency; $expectedVersion; $version : Text
	var $orderId; $customer; $productRef; $quantity; $label; $price : Text
	var $hasOrder; $hasLine : Boolean
	var $rows : Integer:=0

	$lab.prepare($scenario)

	// --- EXIT 1 : the configuration file is missing
	If (Not($lab.configFile.exists))
		$result.message:="Configuration file not found."
		$result.exit:=1
		return $result
	End if

	$configRef:=DOM Parse XML source($lab.configFile.platformPath)
	defer(DOM CLOSE XML($configRef))
	$exportNode:=This._findChild($configRef; "export")

	// --- EXIT 2 : the configuration has no <export> node
	If ($exportNode="")
		$result.message:="Invalid configuration: <export> node is missing."
		$result.exit:=2
		return $result
	End if

	DOM GET XML ATTRIBUTE BY NAME($exportNode; "currency"; $currency)
	$catalogNode:=This._findChild($configRef; "catalog")
	DOM GET XML ATTRIBUTE BY NAME($catalogNode; "version"; $expectedVersion)

	// --- EXIT 3 : the catalog file is missing
	If (Not($lab.catalogFile.exists))
		$result.message:="Catalog file not found."
		$result.exit:=3
		return $result
	End if

	$catalogRef:=DOM Parse XML source($lab.catalogFile.platformPath)
	defer(DOM CLOSE XML($catalogRef))
	DOM GET XML ATTRIBUTE BY NAME($catalogRef; "version"; $version)

	// --- EXIT 4 : the catalog version does not match the configuration
	If ($version#$expectedVersion)
		$result.message:="Catalog is version "+$version+" while "+$expectedVersion+" is expected."
		$result.exit:=4
		return $result
	End if

	// --- EXIT 5 : the orders file is missing
	If (Not($lab.ordersFile.exists))
		$result.message:="Orders file not found."
		$result.exit:=5
		return $result
	End if

	$ordersRef:=DOM Parse XML source($lab.ordersFile.platformPath)
	defer(DOM CLOSE XML($ordersRef))
	$orderNode:=DOM Get first child XML element($ordersRef)
	$hasOrder:=(OK=1)

	// --- EXIT 6 : there is nothing to consolidate
	If (Not($hasOrder))
		$result.message:="No order to consolidate."
		$result.exit:=6
		return $result
	End if

	// --- EXIT 7 : the report template is missing
	If (Not($lab.templateFile.exists))
		$result.message:="Report template not found."
		$result.exit:=7
		return $result
	End if

	$templateRef:=DOM Parse XML source($lab.templateFile.platformPath)
	defer(DOM CLOSE XML($templateRef))
	$rowsNode:=This._findChild($templateRef; "rows")

	// --- EXIT 8 : the template has no <rows> placeholder
	If ($rowsNode="")
		$result.message:="Invalid template: the <rows> placeholder is missing."
		$result.exit:=8
		return $result
	End if

	$reportRef:=DOM Create XML Ref("report")
	defer(DOM CLOSE XML($reportRef))
	DOM SET XML ATTRIBUTE($reportRef; "currency"; $currency)
	$rowsRef:=DOM Create XML element($reportRef; "rows")

	While ($hasOrder)
		DOM GET XML ATTRIBUTE BY NAME($orderNode; "id"; $orderId)
		DOM GET XML ATTRIBUTE BY NAME($orderNode; "customer"; $customer)
		$lineNode:=DOM Get first child XML element($orderNode)
		$hasLine:=(OK=1)

		While ($hasLine)
			DOM GET XML ATTRIBUTE BY NAME($lineNode; "ref"; $productRef)
			DOM GET XML ATTRIBUTE BY NAME($lineNode; "qty"; $quantity)
			$productNode:=This._findProduct($catalogRef; $productRef)

			// --- EXIT 9 : an order line references an unknown product
			If ($productNode="")
				$result.message:="Unknown product "+$productRef+" in order "+$orderId+"."
				$result.exit:=9
				return $result
			End if

			DOM GET XML ATTRIBUTE BY NAME($productNode; "label"; $label)
			DOM GET XML ATTRIBUTE BY NAME($productNode; "price"; $price)
			$rowNode:=DOM Create XML element($rowsRef; "row")
			DOM SET XML ATTRIBUTE($rowNode; "order"; $orderId; "customer"; $customer)
			DOM SET XML ATTRIBUTE($rowNode; "product"; $label; "qty"; $quantity; "price"; $price)
			$rows:=$rows+1

			$lineNode:=DOM Get next sibling XML element($lineNode)
			$hasLine:=(OK=1)
		End while

		$orderNode:=DOM Get next sibling XML element($orderNode)
		$hasOrder:=(OK=1)
	End while

	// --- EXIT 10 : the output folder is gone
	If (Not($lab.folder.exists))
		$result.message:="Output folder is not available."
		$result.exit:=10
		return $result
	End if

	DOM EXPORT TO FILE($reportRef; $lab.outputFile.platformPath)
	$result.xml:=$lab.outputFile.getText()

	// --- EXIT 11 : success
	$result.ok:=True
	$result.exit:=11
	$result.message:="Report built with "+String($rows)+" rows."
	return $result

Function _findChild($parent : Text; $name : Text) : Text
	var $node; $nodeName : Text
	$node:=DOM Get first child XML element($parent; $nodeName)
	While (OK=1)
		If ($nodeName=$name)
			return $node
		End if
		$node:=DOM Get next sibling XML element($node; $nodeName)
	End while
	return ""

Function _findProduct($catalogRef : Text; $productRef : Text) : Text
	var $node; $nodeName; $ref : Text
	$node:=DOM Get first child XML element($catalogRef; $nodeName)
	While (OK=1)
		DOM GET XML ATTRIBUTE BY NAME($node; "ref"; $ref)
		If ($ref=$productRef)
			return $node
		End if
		$node:=DOM Get next sibling XML element($node; $nodeName)
	End while
	return ""
