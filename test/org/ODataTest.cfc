/*
	OData for ColdFusion and Railo Applications

	The MIT License (MIT)

	Copyright (c) 2014 Damon Miller

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
*/
component extends="mxunit.framework.TestCase" {

	public void function testParseFilter() {
		var OData = new org.OData();

		// verify structure of result
		var result = OData.parseFilter("column eq 'value'");
		assertTrue(isStruct(result));
		assertEquals(8, structCount(result));

		// verify allowed
		assertTrue(structKeyExists(result, "allowed"));
		assertTrue(isBoolean(result.allowed));
		assertTrue(result.allowed);

		// verify columnName
		assertTrue(structKeyExists(result, "columnName"));
		assertTrue(isSimpleValue(result.columnName));
		assertEquals("column", result.columnName);

		// verify columnValue
		assertTrue(structKeyExists(result, "columnValue"));
		assertTrue(isSimpleValue(result.columnValue));
		assertEquals(":column1", result.columnValue);

		// verify method
		assertTrue(structKeyExists(result, "method"));
		assertTrue(isSimpleValue(result.method));
		assertEquals("handleGenericOperator", result.method);

		// verify operator
		assertTrue(structKeyExists(result, "operator"));
		assertTrue(isSimpleValue(result.operator));
		assertEquals("=", result.operator);

		// verify parameters
		assertTrue(structKeyExists(result, "parameters"));
		assertTrue(isStruct(result.parameters));
		assertTrue(structKeyExists(result.parameters, "column1"));
		assertTrue(isSimpleValue(result.parameters["column1"]));
		assertEquals("value", result.parameters["column1"]);

		// verify sql
		assertTrue(structKeyExists(result, "sql"));
		assertTrue(isSimpleValue(result.sql));
		assertEquals("column = :column1", result.sql);
	}

	public void function testParseFilter_allowed() {
		var OData = new org.OData();

		// verify optional 'allowed' argument
		var result = OData.parseFilter("column_a eq 'value_a' and column_b ne 'value_b' and column_c eq 'value_c'", ["column_b"]);

		// verify parameters
		assertEquals(1, structCount(result.parameters));
		assertTrue(structKeyExists(result.parameters, "column_b2"));
		assertTrue(isSimpleValue(result.parameters["column_b2"]));
		assertEquals("value_b", result.parameters["column_b2"]);

		// verify sql
		assertEquals("column_b <> :column_b2", result.sql);

		var result = OData.parseFilter("a eq 'b'", ["c"]);
		$assert.isEqual(0, structCount(result.parameters));
		$assert.isEqual("", result.sql);

		var result = OData.parseFilter("column_a eq 'value_a' and column_b ne 'value_b' and column_c eq 'value_c'", ["column_d"]);
		assertEquals(0, structCount(result.parameters));
		assertEquals("", result.sql);

		var result = OData.parseFilter("a eq 'b' and b eq 'c' and d eq 'e' and c eq 'd'", ["a","b","c"]);
		$assert.isEqual(3, structCount(result.parameters));
		$assert.isFalse(structKeyExists(result.parameters, "d3"));
		$assert.isEqual("a = :a1 and b = :b2 and c = :c4", result.sql);
	}

	public void function testParseFilter_eq() {
		var OData = new org.OData();

		var result = OData.parseFilter("City eq 'Miami'");
		assertEquals("City = :City1", result.sql);
		assertEquals("Miami", result.parameters["City1"]);

		// check for irish bug
		var result = OData.parseFilter("lastName eq 'O''Malley'");
		assertEquals("O'Malley", result.parameters["lastName1"]);

		// *** negative test cases ***
		// determine how to handle these cases

		// missing single quotes around value
		//FAILS: result = OData.parseFilter("firstName eq john");

		// operators are case-sensitive
		//FAILS: result = OData.parseFilter("firstName Eq 'john'");
	}

	public void function testParseFilter_and() {
		var OData = new org.OData();

		var result = OData.parseFilter("Country_Region_Code eq 'ES' and Payment_Terms_Code eq '14 DAYS'");
		assertEquals("Country_Region_Code = :Country_Region_Code1 and Payment_Terms_Code = :Payment_Terms_Code2", result.sql);
		assertEquals("ES", result.parameters["Country_Region_Code1"]);
		assertEquals("14 DAYS", result.parameters["Payment_Terms_Code2"]);
	}

	public void function testParseFilter_or() {
		var OData = new org.OData();

		var result = OData.parseFilter("Country_Region_Code eq 'ES' or Country_Region_Code eq 'US'");
		assertEquals("Country_Region_Code = :Country_Region_Code1 or Country_Region_Code = :Country_Region_Code2", result.sql);
		assertEquals("ES", result.parameters["Country_Region_Code1"]);
		assertEquals("US", result.parameters["Country_Region_Code2"]);

	}

	public void function testParseFilter_lt() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No lt 610");
		assertEquals("Entry_No < :Entry_No1", result.sql);
		assertEquals(610, result.parameters["Entry_No1"]);
	}

	public void function testParseFilter_gt() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No gt 610");
		assertEquals("Entry_No > :Entry_No1", result.sql);
		assertEquals(610, result.parameters["Entry_No1"]);
	}

	public void function testParseFilter_ge() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No ge 610");
		assertEquals("Entry_No >= :Entry_No1", result.sql);
		assertEquals(610, result.parameters["Entry_No1"]);
	}

	public void function testParseFilter_le() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No le 610");
		assertEquals("Entry_No <= :Entry_No1", result.sql);
		assertEquals(610, result.parameters["Entry_No1"]);
	}

	public void function testParseFilter_ne() {
		var OData = new org.OData();

		var result = OData.parseFilter("VAT_Bus_Posting_Group ne 'EXPORT'");
		assertEquals("VAT_Bus_Posting_Group <> :VAT_Bus_Posting_Group1", result.sql);
		assertEquals("EXPORT", result.parameters["VAT_Bus_Posting_Group1"]);
	}

	public void function testParseFilter_endswith() {
		var OData = new org.OData();

		var result = OData.parseFilter("endswith(VAT_Bus_Posting_Group,'RT')");
		assertEquals("VAT_Bus_Posting_Group like :VAT_Bus_Posting_Group1", result.sql);
		assertEquals("%RT", result.parameters["VAT_Bus_Posting_Group1"]);
	}

	public void function testParseFilter_startswith() {
		var OData = new org.OData();

		var result = OData.parseFilter("startswith(Name, 'S')");
		assertEquals("Name like :Name1", result.sql);
		assertEquals("S%", result.parameters["Name1"]);
	}

	public void function testParseFilter_substringof() {
		var OData = new org.OData();

		var result = OData.parseFilter("substringof('urn', Name)");
		assertEquals("Name like :Name1", result.sql);
		assertEquals("%urn%", result.parameters["Name1"]);
	}

	public void function testParseFilter_length() {
		var OData = new org.OData();

		var result = OData.parseFilter("length(Name) gt 20");
		assertEquals("len(Name) > :Name1", result.sql);
		assertEquals(20, result.parameters["Name1"]);
	}

	/*public void function testParseFilter_indexof() {
		var OData = new org.OData();

		var result = OData.parseFilter("indexof(Location_Code, 'BLUE') eq 0");
		assertEquals("charindex(Location_Code, :Location_Code1) = 0", result.sql);
		assertEquals("BLUE", result.parameters["Location_Code1"]);
	}

	public void function testParseFilter_replace() {
		var OData = new org.OData();

		var result = OData.parseFilter("replace(City, 'Miami', 'Tampa') eq 'CODERED'");
		assertEquals("replace(City, :City1, 'Tampa') = 'CODERED'", result.sql);
		assertEquals("Miami", result.parameters["City1"]);
	}

	public void function testParseFilter_substring() {
		var OData = new org.OData();

		var result = OData.parseFilter("substring(Location_Code, 5) eq 'RED'");
		assertEquals("substring(Location_Code, 5) = :Location_Code1", result.sql);
		assertEquals("RED", result.parameters["Location_Code1"]);
	}*/

	// NOTE: need to test paranthesis, not, arithmetic operators, and other methods not noted above

}