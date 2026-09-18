/*  Pricing engine — WITHOUT defer.

	One benchmark opened at the top of compute(), twelve possible exit points.
	Every single one of them has to close the measure, so the same call is
	repeated twelve times down the method.

	Except that one was forgotten (look at EXIT 11): that measure will never
	be recorded, and the profile silently lies.
*/

singleton Class constructor()

Function compute($scenario : Text) : Object
	var $lab : cs.PricingLab:=cs.PricingLab.me
	var $benchmark : cs.Benchmark:=cs.Benchmark.new("PricingEngine.compute")
	var $result : Object:={ok: False; exit: 0; message: ""; total: 0}
	var $order : Object:=$lab.order($scenario)
	var $customer; $line; $priced; $discount : Object
	var $subtotal; $rate : Real

	// --- EXIT 1 : nothing to price
	If ($order=Null)
		$benchmark.stop()
		$result.message:="No order supplied."
		$result.exit:=1
		return $result
	End if

	// --- EXIT 2 : the order has no identifier
	If ($order.id="")
		$benchmark.stop()
		$result.message:="The order has no identifier."
		$result.exit:=2
		return $result
	End if

	// --- EXIT 3 : the order is empty
	If ($order.lines.length=0)
		$benchmark.stop()
		$result.message:="Order "+$order.id+" has no line."
		$result.exit:=3
		return $result
	End if

	$customer:=$lab.customer($order.customer)

	// --- EXIT 4 : unknown customer
	If ($customer=Null)
		$benchmark.stop()
		$result.message:="Unknown customer "+$order.customer+"."
		$result.exit:=4
		return $result
	End if

	// --- EXIT 5 : the customer account is blocked
	If ($customer.status="blocked")
		$benchmark.stop()
		$result.message:="Customer "+$customer.name+" is blocked."
		$result.exit:=5
		return $result
	End if

	// --- EXIT 6 : the customer reached its credit limit
	If ($customer.balance>=$customer.creditLimit)
		$benchmark.stop()
		$result.message:="Customer "+$customer.name+" reached its credit limit."
		$result.exit:=6
		return $result
	End if

	Try
		$rate:=This._conversionRate($customer.currency)
	Catch
		// --- EXIT 7 : unsupported currency, the error is caught
		$benchmark.stop()
		$result.message:="Currency "+$customer.currency+" is not supported."
		$result.exit:=7
		return $result
	End try

	For each ($line; $order.lines)

		// --- EXIT 8 : invalid quantity
		If ($line.qty<=0)
			$benchmark.stop()
			$result.message:="Invalid quantity on product "+$line.ref+"."
			$result.exit:=8
			return $result
		End if

		$priced:=This._priceLine($line)

		// --- EXIT 9 : the line could not be priced
		If (Not($priced.ok))
			$benchmark.stop()
			$result.message:=$priced.message
			$result.exit:=9
			return $result
		End if

		$subtotal:=$subtotal+$priced.amount
	End for each

	// --- EXIT 10 : below the minimum billable amount
	If ($subtotal<$lab.minimumAmount)
		$benchmark.stop()
		$result.message:="Order "+$order.id+" is below the minimum billable amount."
		$result.exit:=10
		return $result
	End if

	$discount:=This._discountFor($customer)

	// --- EXIT 11 : the discount rules conflict
	If (Not($discount.ok))
		// !! FORGOTTEN here: $benchmark.stop() -> this measure is lost for good
		$result.message:=$discount.message
		$result.exit:=11
		return $result
	End if

	// --- EXIT 12 : the order is priced
	$benchmark.stop()
	$result.ok:=True
	$result.exit:=12
	$result.total:=Round($subtotal*(1-$discount.rate)*$rate; 2)
	$result.message:="Order "+$order.id+" priced: "+String($result.total)+" "+$customer.currency+"."
	return $result

Function _priceLine($line : Object) : Object
	var $product : Object

	If ($line.ref=Null)
		return {ok: False; message: "A line carries no product reference."}
	End if

	$product:=cs.PricingLab.me.product($line.ref)
	If ($product=Null)
		return {ok: False; message: "Unknown product "+$line.ref+"."}
	End if

	return {ok: True; label: $product.label; amount: $product.price*$line.qty}

Function _discountFor($customer : Object) : Object
	If ($customer.tier="bronze")
		return {ok: True; rate: 0}
	End if

	If (($customer.tier="gold") && ($customer.voucher#Null))
		return {ok: False; message: "Voucher "+$customer.voucher+" cannot be combined with the gold tier."}
	End if

	If ($customer.tier="gold")
		return {ok: True; rate: 0.1}
	End if

	return {ok: True; rate: 0.05}

Function _conversionRate($currency : Text) : Real
	var $rates : Object:={EUR: 1; USD: 0.92; GBP: 1.17}
	If ($rates[$currency]=Null)
		throw({errCode: 50042; message: "Unsupported currency "+$currency})
	End if
	return $rates[$currency]
