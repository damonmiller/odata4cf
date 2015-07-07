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
		assertEquals(7, structCount(result));

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
		assertEquals("column=:column1", result.sql);
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
		assertEquals("column_b!=:column_b2", result.sql);

		var result = OData.parseFilter("a eq 'b'", ["c"]);
		$assert.isEqual(0, structCount(result.parameters));
		$assert.isEqual("", result.sql);

		var result = OData.parseFilter("column_a eq 'value_a' and column_b ne 'value_b' and column_c eq 'value_c'", ["column_d"]);
		assertEquals(0, structCount(result.parameters));
		assertEquals("", result.sql);

		var result = OData.parseFilter("a eq 'b' and b eq 'c' and d eq 'e' and c eq 'd'", ["a","b","c"]);
		$assert.isEqual(3, structCount(result.parameters));
		$assert.isFalse(structKeyExists(result.parameters, "d3"));
		$assert.isEqual("a=:a1 and b=:b2 and c=:c4", result.sql);
	}

	public void function testParseFilter_eq() {
		var OData = new org.OData();

		var result = OData.parseFilter("firstName eq 'john'");
		assertEquals("firstName=:firstName1", result.sql);
		assertEquals("john", result.parameters["firstName1"]);

		var result = OData.parseFilter("lastName eq 'doe'");
		assertEquals("lastName=:lastName1", result.sql);
		assertEquals("doe", result.parameters["lastName1"]);

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

	public void function testParseFilter_ne() {
		var OData = new org.OData();

		var result = OData.parseFilter("isDeleted ne 0");
		assertEquals("isDeleted!=:isDeleted1", result.sql);
		assertEquals(0, result.parameters["isDeleted1"]);
	}

	public void function testParseFilter_gt() {
		var OData = new org.OData();

		var result = OData.parseFilter("count gt 42");
		assertEquals("count>:count1", result.sql);
		assertEquals(42, result.parameters["count1"]);
	}

	public void function testParseFilter_ge() {
		var OData = new org.OData();

		var result = OData.parseFilter("count ge 42");
		assertEquals("count>=:count1", result.sql);
		assertEquals(42, result.parameters["count1"]);
	}

	public void function testParseFilter_lt() {
		var OData = new org.OData();

		var result = OData.parseFilter("count lt 42");
		assertEquals("count<:count1", result.sql);
		assertEquals(42, result.parameters["count1"]);
	}

	public void function testParseFilter_le() {
		var OData = new org.OData();

		var result = OData.parseFilter("count le 42");
		assertEquals("count<=:count1", result.sql);
		assertEquals(42, result.parameters["count1"]);
	}

	public void function testParseFilter_startswith() {
		var OData = new org.OData();

		var result = OData.parseFilter("startswith(firstName, 'jo')");
		assertEquals("firstName like :firstName1", result.sql);
		assertEquals("jo%", result.parameters["firstName1"]);
	}

	public void function testParseFilter_endswith() {
		var OData = new org.OData();

		var result = OData.parseFilter("endswith(firstName, 'hn')");
		assertEquals("firstName like :firstName1", result.sql);
		assertEquals("%hn", result.parameters["firstName1"]);
	}

	public void function testParseFilter_substringOf() {
		var OData = new org.OData();

		var result = OData.parseFilter("substringof('oh', firstName)");
		assertEquals("firstName like :firstName1", result.sql);
		assertEquals("%oh%", result.parameters["firstName1"]);
	}

	public void function testParseFilter_and() {
		var OData = new org.OData();

		var result = OData.parseFilter("firstName eq 'john' and lastName eq 'doe'");
		assertEquals("firstName=:firstName1 and lastName=:lastName2", result.sql);
		assertEquals("john", result.parameters["firstName1"]);
		assertEquals("doe", result.parameters["lastName2"]);

		var result = OData.parseFilter("substringof('jo', firstName) and substringof('hn', firstName)");
		assertEquals("firstName like :firstName1 and firstName like :firstName2", result.sql);
		assertEquals("%jo%", result.parameters["firstName1"]);
		assertEquals("%hn%", result.parameters["firstName2"]);

	}

	public void function testParseFilter_or() {
		var OData = new org.OData();

		var result = OData.parseFilter("firstName eq 'john' or firstName eq 'jane'");
		assertEquals("firstName=:firstName1 or firstName=:firstName2", result.sql);
		assertEquals("john", result.parameters["firstName1"]);
		assertEquals("jane", result.parameters["firstName2"]);

	}

	// NOTE: need to test paranthesis, not, arithmetic operators, and other methods not noted above

}