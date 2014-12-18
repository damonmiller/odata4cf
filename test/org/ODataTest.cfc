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

	public void function parseFilterTest() {
		var OData = new org.OData();

		// verify structure of result
		var result = OData.parseFilter("column eq 'value'");
		assertTrue(isStruct(result));
		assertEquals(2, structCount(result));

		// verify sql structure
		assertTrue(structKeyExists(result, "sql"));
		assertTrue(isSimpleValue(result.sql));
		assertEquals("column=:column", result.sql);

		// verify parameters structure
		assertTrue(structKeyExists(result, "parameters"));
		assertTrue(isStruct(result.parameters));
		assertTrue(structKeyExists(result.parameters, "column"));
		assertTrue(isSimpleValue(result.parameters["column"]));
		assertEquals("value", result.parameters["column"]);

		// * verify expressions *

		// eq
		result = OData.parseFilter("firstName eq 'john'");
		assertEquals("firstName=:firstName", result.sql);
		assertEquals("john", result.parameters["firstName"]);
		result = OData.parseFilter("lastName eq 'doe'");
		assertEquals("lastName=:lastName", result.sql);
		assertEquals("doe", result.parameters["lastName"]);
		// check for irish bug
		result = OData.parseFilter("lastName eq 'O''Malley'");
		assertEquals("O'Malley", result.parameters["lastName"]);

		// neq
		//FAILS: result = OData.parseFilter("isDeleted neq 0");
		//assertEquals("isDeleted=:isDeleted", result.sql);
		//assertEquals(0, result.parameters["isDeleted"]);

		// gt

		// ge

		// lt

		// le

		// startsWith

		// endsWith

		// substringOf

		// and
		//FAILS: result = OData.parseFilter("firstName eq 'john' and lastName eq 'doe'");

		// or
		//FAILS: result = OData.parseFilter("firstName eq 'john' or firstName eq 'jane'");

		// NOTE: need to test paranthesis, not, arithmetic operators, and other methods not noted above


		// *** negative test cases ***
		// determine how to handle these cases

		// missing single quotes around value
		//FAILS: result = OData.parseFilter("firstName eq john");

		// operators are case-sensitive
		//FAILS: result = OData.parseFilter("firstName Eq 'john'");
	}

}