/*  Sample data for the pricing engines. A scenario selects the order that
	drives the engine to a given exit point.
*/

property catalog : Collection
property customers : Collection
property minimumAmount : Real

singleton Class constructor()
	This.minimumAmount:=50
	This.catalog:=[\
		{ref: "P-100"; label: "Keyboard"; price: 49}; \
		{ref: "P-200"; label: "Mouse"; price: 25.5}; \
		{ref: "P-300"; label: "Monitor"; price: 189.9}\
		]
	This.customers:=[\
		{code: "ACME"; name: "ACME"; status: "active"; tier: "silver"; currency: "EUR"; balance: 1200; creditLimit: 10000}; \
		{code: "GLOBEX"; name: "Globex"; status: "blocked"; tier: "silver"; currency: "EUR"; balance: 800; creditLimit: 5000}; \
		{code: "INITECH"; name: "Initech"; status: "active"; tier: "silver"; currency: "XYZ"; balance: 300; creditLimit: 5000}; \
		{code: "HOOLI"; name: "Hooli"; status: "active"; tier: "gold"; currency: "EUR"; balance: 500; creditLimit: 9000; voucher: "SUMMER"}\
		]

Function product($ref : Text) : Object
	return This.catalog.query("ref = :1"; $ref).first()

Function customer($code : Text) : Object
	return This.customers.query("code = :1"; $code).first()

Function order($scenario : Text) : Object
	Case of
		: ($scenario="blockedCustomer")
			return {id: "A-002"; customer: "GLOBEX"; lines: [{ref: "P-100"; qty: 2}]}
		: ($scenario="unknownProduct")
			return {id: "A-003"; customer: "ACME"; lines: [{ref: "P-100"; qty: 1}; {ref: "P-999"; qty: 3}]}
		: ($scenario="badCurrency")
			return {id: "A-004"; customer: "INITECH"; lines: [{ref: "P-200"; qty: 2}]}
		: ($scenario="discountConflict")
			return {id: "A-005"; customer: "HOOLI"; lines: [{ref: "P-300"; qty: 4}]}
		Else
			return {id: "A-001"; customer: "ACME"; lines: [{ref: "P-100"; qty: 2}; {ref: "P-300"; qty: 1}]}
	End case
