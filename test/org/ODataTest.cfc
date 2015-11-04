/*
	OData for ColdFusion and Lucee Applications

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
component extends="testbox.system.BaseSpec" {

	public void function testParseFilter() {
		var OData = new org.OData();

		// verify structure of result
		var result = OData.parseFilter("lhs eq 'rhs'");
		$assert.isTrue(isStruct(result));
		$assert.isEqual(7, structCount(result));

		// verify allowed
		$assert.isTrue(structKeyExists(result, "allowed"));
		$assert.isTrue(isBoolean(result.allowed));
		$assert.isTrue(result.allowed);

		// verify ODataType
		$assert.isTrue(structKeyExists(result, "ODataType"));
		$assert.isTrue(isSimpleValue(result.ODataType));
		$assert.isEqual("EqExpression", result.ODataType);

		// verify operator
		$assert.isTrue(structKeyExists(result, "SQLValue"));
		$assert.isTrue(isSimpleValue(result.SQLValue));
		$assert.isEqual("=", result.SQLValue);

		// verify parameters
		$assert.isTrue(structKeyExists(result, "parameters"));
		$assert.isTrue(isStruct(result.parameters));
		$assert.isTrue(structKeyExists(result.parameters, "parameter1"));
		$assert.isTrue(isSimpleValue(result.parameters["parameter1"]));
		$assert.isEqual("rhs", result.parameters["parameter1"]);

		// verify sql
		$assert.isTrue(structKeyExists(result, "SQL"));
		$assert.isTrue(isSimpleValue(result.SQL));
		$assert.isEqual("lhs = :parameter1", result.SQL);

		// verify structure of result
		var result = OData.parseFilter("'lhs' eq rhs");
		$assert.isTrue(isStruct(result));
		$assert.isEqual(7, structCount(result));

		// verify allowed
		$assert.isTrue(structKeyExists(result, "allowed"));
		$assert.isTrue(isBoolean(result.allowed));
		$assert.isTrue(result.allowed);

		// verify ODataType
		$assert.isTrue(structKeyExists(result, "ODataType"));
		$assert.isTrue(isSimpleValue(result.ODataType));
		$assert.isEqual("EqExpression", result.ODataType);

		// verify operator
		$assert.isTrue(structKeyExists(result, "SQLValue"));
		$assert.isTrue(isSimpleValue(result.SQLValue));
		$assert.isEqual("=", result.SQLValue);

		// verify parameters
		$assert.isTrue(structKeyExists(result, "parameters"));
		$assert.isTrue(isStruct(result.parameters));
		$assert.isTrue(structKeyExists(result.parameters, "parameter1"));
		$assert.isTrue(isSimpleValue(result.parameters["parameter1"]));
		$assert.isEqual("lhs", result.parameters["parameter1"]);

		// verify sql
		$assert.isTrue(structKeyExists(result, "SQL"));
		$assert.isTrue(isSimpleValue(result.SQL));
		$assert.isEqual(":parameter1 = rhs", result.SQL);

		// *** negative test cases ***
		// determine how to handle these cases

		// missing single quotes around value
		//FAILS: result = OData.parseFilter("firstName eq john");

		// operators are case-sensitive
		//FAILS: result = OData.parseFilter("firstName Eq 'john'");
	}

	public void function testParseFilter_literals() {
		var OData = new org.OData();

		var result = OData.parseFilter("col eq 'string'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);

		var result = OData.parseFilter("col eq 42");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);

		/* FAILS: Unable to read expression with tokens: [[3], [.], [14]]

		var result = OData.parseFilter("col eq 3.14");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("DoubleLiteral", result.rhs[1].ODataType);*/

		var result = OData.parseFilter("col eq true");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("BooleanLiteral", result.rhs[1].ODataType);
	}

	public void function testParseFilter_parentheses() {
		var OData = new org.OData();

		// verify structure of result
		var result = OData.parseFilter("a ne b and (lhs eq 'rhs' or 'lhs' eq rhs)");
		$assert.isEqual("BoolParenExpression", result.parsed[3].ODataType);
		$assert.isTrue(isStruct(result));
		$assert.isEqual(3, structCount(result));

		// verify parameters
		$assert.isTrue(structKeyExists(result, "parameters"));
		$assert.isTrue(isStruct(result.parameters));
		$assert.isEqual(2, structCount(result.parameters));
		$assert.isTrue(structKeyExists(result.parameters, "parameter1"));
		$assert.isEqual("rhs", result.parameters["parameter1"]);
		$assert.isTrue(structKeyExists(result.parameters, "parameter2"));
		$assert.isEqual("lhs", result.parameters["parameter2"]);

		// verify sql
		$assert.isTrue(structKeyExists(result, "sql"));
		$assert.isTrue(isSimpleValue(result.sql));
		$assert.isEqual("a <> b and ( lhs = :parameter1 or :parameter2 = rhs )", result.sql);
	}

	public void function testParseFilter_allowed() {
		var OData = new org.OData();

		// verify optional 'allowed' argument
		var result = OData.parseFilter("column_a eq 'value_a' and (column_b ne 'value_b' or column_c eq 'value_c')", ["column_b"]);

		// verify parameters
		$assert.isEqual(1, structCount(result.parameters));
		$assert.isTrue(structKeyExists(result.parameters, "parameter2"));
		$assert.isTrue(isSimpleValue(result.parameters["parameter2"]));
		$assert.isEqual("value_b", result.parameters["parameter2"]);

		// verify sql
		$assert.isEqual("( column_b <> :parameter2 )", result.sql);

		var result = OData.parseFilter("a eq 'b'", ["c"]);
		$assert.isEqual(0, structCount(result.parameters));
		$assert.isEqual("", result.sql);

		var result = OData.parseFilter("column_a eq 'value_a' and column_b ne 'value_b' and column_c eq 'value_c'", ["column_d"]);
		$assert.isEqual(0, structCount(result.parameters));
		$assert.isEqual("", result.sql);

		var result = OData.parseFilter("a eq 'b' and b eq 'c' and d eq 'e' and c eq 'd'", ["a","b","c"]);
		$assert.isEqual(3, structCount(result.parameters));
		$assert.isFalse(structKeyExists(result.parameters, "parameter3"));
		$assert.isEqual("a = :parameter1 and b = :parameter2 and c = :parameter4", result.sql);
	}

	public void function testParseFilter_eq() {
		var OData = new org.OData();

		var result = OData.parseFilter("City eq 'Miami'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("City = :parameter1", result.sql);
		$assert.isEqual("Miami", result.parameters["parameter1"]);

		var result = OData.parseFilter("'Miami' eq City");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = City", result.sql);
		$assert.isEqual("Miami", result.parameters["parameter1"]);

		// check for irish bug
		var result = OData.parseFilter("lastName eq 'O''Malley'");
		$assert.isEqual("O'Malley", result.parameters["parameter1"]);
	}

	public void function testParseFilter_null() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No eq null");
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("NullLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Entry_No = :parameter1", result.sql);
		$assert.isEqual(1, structCount(result.parameters));
		$assert.isTrue(structKeyList(result.parameters) == "parameter1");
		$assert.isFalse(structKeyExists(result.parameters, "parameter1"));

		var result = OData.parseFilter("null eq Entry_No");
		$assert.isEqual("NullLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = Entry_No", result.sql);
		$assert.isEqual(1, structCount(result.parameters));
		$assert.isTrue(structKeyList(result.parameters) == "parameter1");
		$assert.isFalse(structKeyExists(result.parameters, "parameter1"));
	}

	public void function testParseFilter_and() {
		var OData = new org.OData();

		var result = OData.parseFilter("Country_Region_Code eq 'ES' and '14 DAYS' eq Payment_Terms_Code");
		$assert.isEqual("EqExpression", result.parsed[1].ODataType);
		$assert.isEqual("AndExpression", result.parsed[2].ODataType);
		$assert.isEqual("EqExpression", result.parsed[3].ODataType);
		$assert.isEqual("Country_Region_Code = :parameter1 and :parameter2 = Payment_Terms_Code", result.sql);
		$assert.isEqual("ES", result.parameters["parameter1"]);
		$assert.isEqual("14 DAYS", result.parameters["parameter2"]);
	}

	public void function testParseFilter_or() {
		var OData = new org.OData();

		var result = OData.parseFilter("Country_Region_Code eq 'ES' or 'US' eq Country_Region_Code");
		$assert.isEqual("EqExpression", result.parsed[1].ODataType);
		$assert.isEqual("OrExpression", result.parsed[2].ODataType);
		$assert.isEqual("EqExpression", result.parsed[3].ODataType);
		$assert.isEqual("Country_Region_Code = :parameter1 or :parameter2 = Country_Region_Code", result.sql);
		$assert.isEqual("ES", result.parameters["parameter1"]);
		$assert.isEqual("US", result.parameters["parameter2"]);
	}

	public void function testParseFilter_lt() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No lt 610");
		$assert.isEqual("LtExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Entry_No < :parameter1", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);

		var result = OData.parseFilter("610 lt Entry_No");
		$assert.isEqual("LtExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 < Entry_No", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);
	}

	public void function testParseFilter_gt() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No gt 610");
		$assert.isEqual("GtExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Entry_No > :parameter1", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);

		var result = OData.parseFilter("610 gt Entry_No");
		$assert.isEqual("GtExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 > Entry_No", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);
	}

	public void function testParseFilter_ge() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No ge 610");
		$assert.isEqual("GeExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Entry_No >= :parameter1", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);

		var result = OData.parseFilter("610 ge Entry_No");
		$assert.isEqual("GeExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 >= Entry_No", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);
	}

	public void function testParseFilter_le() {
		var OData = new org.OData();

		var result = OData.parseFilter("Entry_No le 610");
		$assert.isEqual("LeExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Entry_No <= :parameter1", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);

		var result = OData.parseFilter("610 le Entry_No");
		$assert.isEqual("LeExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 <= Entry_No", result.sql);
		$assert.isEqual(610, result.parameters["parameter1"]);
	}

	public void function testParseFilter_ne() {
		var OData = new org.OData();

		var result = OData.parseFilter("VAT_Bus_Posting_Group ne 'EXPORT'");
		$assert.isEqual("NeExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("VAT_Bus_Posting_Group <> :parameter1", result.sql);
		$assert.isEqual("EXPORT", result.parameters["parameter1"]);

		var result = OData.parseFilter("'EXPORT' ne VAT_Bus_Posting_Group");
		$assert.isEqual("NeExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("EntitySimpleProperty", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 <> VAT_Bus_Posting_Group", result.sql);
		$assert.isEqual("EXPORT", result.parameters["parameter1"]);
	}

	public void function testParseFilter_endswith() {
		var OData = new org.OData();

		var result = OData.parseFilter("endswith(VAT_Bus_Posting_Group,'RT')");
		$assert.isEqual("EndsWithMethodCallExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("VAT_Bus_Posting_Group like :parameter1", result.sql);
		$assert.isEqual("%RT", result.parameters["parameter1"]);
	}

	public void function testParseFilter_startswith() {
		var OData = new org.OData();

		var result = OData.parseFilter("startswith(Name, 'S')");
		$assert.isEqual("StartsWithMethodCallExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Name like :parameter1", result.sql);
		$assert.isEqual("S%", result.parameters["parameter1"]);
	}

	public void function testParseFilter_substringof() {
		var OData = new org.OData();

		var result = OData.parseFilter("substringof('urn', Name)");
		$assert.isEqual("SubstringOfMethodCallExpression", result.ODataType);
		$assert.isEqual("EntitySimpleProperty", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("Name like :parameter1", result.sql);
		$assert.isEqual("%urn%", result.parameters["parameter1"]);
	}

	public void function testParseFilter_length() {
		var OData = new org.OData();

		var result = OData.parseFilter("length(Name) gt 20");
		$assert.isEqual("GtExpression", result.ODataType);
		$assert.isEqual("LengthMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("LEN( Name ) > :parameter1", result.sql);
		$assert.isEqual(20, result.parameters["parameter1"]);

		var result = OData.parseFilter("length('Name') gt 20");
		$assert.isEqual("GtExpression", result.ODataType);
		$assert.isEqual("LengthMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("LEN( :parameter1 ) > :parameter2", result.sql);
		$assert.isEqual("Name", result.parameters["parameter1"]);
		$assert.isEqual(20, result.parameters["parameter2"]);

		var result = OData.parseFilter("20 gt length(Name)");
		$assert.isEqual("GtExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("LengthMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 > LEN( Name )", result.sql);
		$assert.isEqual(20, result.parameters["parameter1"]);

		var result = OData.parseFilter("20 gt length('Name')");
		$assert.isEqual("GtExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("LengthMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 > LEN( :parameter2 )", result.sql);
		$assert.isEqual(20, result.parameters["parameter1"]);
		$assert.isEqual("Name", result.parameters["parameter2"]);
	}

	public void function testParseFilter_indexof() {
		var OData = new org.OData();

		var result = OData.parseFilter("indexof(Location_Code, 'BLUE') eq 0");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IndexOfMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("CHARINDEX( :parameter1 , Location_Code ) = :parameter2", result.sql);
		$assert.isEqual("BLUE", result.parameters["parameter1"]);
		$assert.isEqual("0", result.parameters["parameter2"]);

		var result = OData.parseFilter("0 eq indexof(Location_Code, 'BLUE')");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("IndexOfMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = CHARINDEX( :parameter2 , Location_Code )", result.sql);
		$assert.isEqual("0", result.parameters["parameter1"]);
		$assert.isEqual("BLUE", result.parameters["parameter2"]);
	}

	public void function testParseFilter_replace() {
		var OData = new org.OData();

		var result = OData.parseFilter("replace(City, 'Miami', 'Tampa') eq 'CODERED'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("ReplaceMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("REPLACE( City , :parameter1 , :parameter2 ) = :parameter3", result.sql);
		$assert.isEqual("Miami", result.parameters["parameter1"]);
		$assert.isEqual("Tampa", result.parameters["parameter2"]);
		$assert.isEqual("CODERED", result.parameters["parameter3"]);

		var result = OData.parseFilter("'CODERED' eq replace(City, 'Miami', 'Tampa')");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("ReplaceMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = REPLACE( City , :parameter2 , :parameter3 )", result.sql);
		$assert.isEqual("CODERED", result.parameters["parameter1"]);
		$assert.isEqual("Miami", result.parameters["parameter2"]);
		$assert.isEqual("Tampa", result.parameters["parameter3"]);
	}

	public void function testParseFilter_substring() {
		var OData = new org.OData();

		var result = OData.parseFilter("substring(Location_Code, 5) eq 'RED'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("SubstringMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("SUBSTRING( Location_Code , :parameter1 ) = :parameter2", result.sql);
		$assert.isEqual(5, result.parameters["parameter1"]);
		$assert.isEqual("RED", result.parameters["parameter2"]);

		var result = OData.parseFilter("substring(Location_Code, 5, 6) eq 'RED'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("SubstringMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("SUBSTRING( Location_Code , :parameter1 , :parameter2 ) = :parameter3", result.sql);
		$assert.isEqual(5, result.parameters["parameter1"]);
		$assert.isEqual(6, result.parameters["parameter2"]);
		$assert.isEqual("RED", result.parameters["parameter3"]);

		var result = OData.parseFilter("'RED' eq substring(Location_Code, 5)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("SubstringMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = SUBSTRING( Location_Code , :parameter2 )", result.sql);
		$assert.isEqual("RED", result.parameters["parameter1"]);
		$assert.isEqual(5, result.parameters["parameter2"]);

		var result = OData.parseFilter("'RED' eq substring(Location_Code, 5, 6)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("SubstringMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = SUBSTRING( Location_Code , :parameter2 , :parameter3 )", result.sql);
		$assert.isEqual("RED", result.parameters["parameter1"]);
		$assert.isEqual(5, result.parameters["parameter2"]);
		$assert.isEqual(6, result.parameters["parameter3"]);
	}

	public void function testParseFilter_tolower() {
		var OData = new org.OData();

		var result = OData.parseFilter("tolower(Location_Code) eq 'code red'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("ToLowerMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("LOWER( Location_Code ) = :parameter1", result.sql);
		$assert.isEqual("code red", result.parameters["parameter1"]);

		var result = OData.parseFilter("'code red' eq tolower(Location_Code)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("ToLowerMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = LOWER( Location_Code )", result.sql);
		$assert.isEqual("code red", result.parameters["parameter1"]);
	}

	public void function testParseFilter_toupper() {
		var OData = new org.OData();

		var result = OData.parseFilter("toupper(FText) eq '2ND ROW'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("ToUpperMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("UPPER( FText ) = :parameter1", result.sql);
		$assert.isEqual("2ND ROW", result.parameters["parameter1"]);

		var result = OData.parseFilter("'2ND ROW' eq toupper(FText)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("ToUpperMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = UPPER( FText )", result.sql);
		$assert.isEqual("2ND ROW", result.parameters["parameter1"]);
	}

	public void function testParseFilter_trim() {
		var OData = new org.OData();

		var result = OData.parseFilter("trim(FCode) eq 'CODE RED'");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("TrimMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual("LTRIM(RTRIM( FCode )) = :parameter1", result.sql);
		$assert.isEqual("CODE RED", result.parameters["parameter1"]);

		var result = OData.parseFilter("'CODE RED' eq trim(FCode)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("TrimMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = LTRIM(RTRIM( FCode ))", result.sql);
		$assert.isEqual("CODE RED", result.parameters["parameter1"]);
	}

	public void function testParseFilter_concat() {
		var OData = new org.OData();

		var result = OData.parseFilter("concat(concat(FText, ', '), FCode) eq '2nd row, CODE RED'");
		$assert.isEqual("CONCAT( CONCAT( FText , :parameter1 ) , FCode ) = :parameter2", result.sql);
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("ConcatMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("ConcatMethodCallExpression", result.lhs[1].SQLArguments[1].ODataType);
		$assert.isEqual("StringLiteral", result.rhs[1].ODataType);
		$assert.isEqual(", ", result.parameters["parameter1"]);
		$assert.isEqual("2nd row, CODE RED", result.parameters["parameter2"]);

		var result = OData.parseFilter("'2nd row, CODE RED' eq concat(concat(FText, ', '), FCode)");
		$assert.isEqual(":parameter1 = CONCAT( CONCAT( FText , :parameter2 ) , FCode )", result.sql);
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("StringLiteral", result.lhs[1].ODataType);
		$assert.isEqual("ConcatMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual("ConcatMethodCallExpression", result.rhs[1].SQLArguments[1].ODataType);
		$assert.isEqual("2nd row, CODE RED", result.parameters["parameter1"]);
		$assert.isEqual(", ", result.parameters["parameter2"]);
	}

	public void function testParseFilter_day() {
		var OData = new org.OData();

		var result = OData.parseFilter("day(FDateTime) eq 12");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("DayMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("DAY( FDateTime ) = :parameter1", result.sql);
		$assert.isEqual(12, result.parameters["parameter1"]);

		var result = OData.parseFilter("12 eq day(FDateTime)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("DayMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = DAY( FDateTime )", result.sql);
		$assert.isEqual(12, result.parameters["parameter1"]);
	}

	public void function testParseFilter_month() {
		var OData = new org.OData();

		var result = OData.parseFilter("month(FDateTime) eq 12");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("MonthMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("MONTH( FDateTime ) = :parameter1", result.sql);
		$assert.isEqual(12, result.parameters["parameter1"]);

		var result = OData.parseFilter("12 eq month(FDateTime)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("MonthMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = MONTH( FDateTime )", result.sql);
		$assert.isEqual(12, result.parameters["parameter1"]);
	}

	public void function testParseFilter_year() {
		var OData = new org.OData();

		var result = OData.parseFilter("year(FDateTime) eq 2010");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("YearMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("YEAR( FDateTime ) = :parameter1", result.sql);
		$assert.isEqual(2010, result.parameters["parameter1"]);

		var result = OData.parseFilter("2010 eq year(FDateTime)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("YearMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = YEAR( FDateTime )", result.sql);
		$assert.isEqual(2010, result.parameters["parameter1"]);
	}

	public void function testParseFilter_hour() {
		var OData = new org.OData();

		var result = OData.parseFilter("hour(FDateTime) eq 1");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("HourMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("HOUR( FDateTime ) = :parameter1", result.sql);
		$assert.isEqual(1, result.parameters["parameter1"]);

		var result = OData.parseFilter("1 eq hour(FDateTime)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("HourMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = HOUR( FDateTime )", result.sql);
		$assert.isEqual(1, result.parameters["parameter1"]);
	}

	public void function testParseFilter_minute() {
		var OData = new org.OData();

		var result = OData.parseFilter("minute(FDateTime) eq 32");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("MinuteMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("MINUTE( FDateTime ) = :parameter1", result.sql);
		$assert.isEqual(32, result.parameters["parameter1"]);

		var result = OData.parseFilter("32 eq minute(FDateTime)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("MinuteMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = MINUTE( FDateTime )", result.sql);
		$assert.isEqual(32, result.parameters["parameter1"]);
	}

	public void function testParseFilter_second() {
		var OData = new org.OData();

		var result = OData.parseFilter("second(FDateTime) eq 0");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("SecondMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("SECOND( FDateTime ) = :parameter1", result.sql);
		$assert.isEqual(0, result.parameters["parameter1"]);

		var result = OData.parseFilter("0 eq second(FDateTime)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("SecondMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = SECOND( FDateTime )", result.sql);
		$assert.isEqual(0, result.parameters["parameter1"]);
	}

	public void function testParseFilter_round() {
		var OData = new org.OData();

		var result = OData.parseFilter("round(FDecimal) eq 1");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("RoundMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("ROUND( FDecimal ) = :parameter1", result.sql);
		$assert.isEqual(1, result.parameters["parameter1"]);

		var result = OData.parseFilter("1 eq round(FDecimal)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("RoundMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = ROUND( FDecimal )", result.sql);
		$assert.isEqual(1, result.parameters["parameter1"]);
	}

	public void function testParseFilter_floor() {
		var OData = new org.OData();

		var result = OData.parseFilter("floor(FDecimal) eq 0");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("FloorMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("FLOOR( FDecimal ) = :parameter1", result.sql);
		$assert.isEqual(0, result.parameters["parameter1"]);

		var result = OData.parseFilter("0 eq floor(FDecimal)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("FloorMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = FLOOR( FDecimal )", result.sql);
		$assert.isEqual(0, result.parameters["parameter1"]);
	}

	public void function testParseFilter_ceiling() {
		var OData = new org.OData();

		var result = OData.parseFilter("ceiling(FDecimal) eq 1");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("CeilingMethodCallExpression", result.lhs[1].ODataType);
		$assert.isEqual("IntegralLiteral", result.rhs[1].ODataType);
		$assert.isEqual("CEILING( FDecimal ) = :parameter1", result.sql);
		$assert.isEqual(1, result.parameters["parameter1"]);

		var result = OData.parseFilter("1 eq ceiling(FDecimal)");
		$assert.isEqual("EqExpression", result.ODataType);
		$assert.isEqual("IntegralLiteral", result.lhs[1].ODataType);
		$assert.isEqual("CeilingMethodCallExpression", result.rhs[1].ODataType);
		$assert.isEqual(":parameter1 = CEILING( FDecimal )", result.sql);
		$assert.isEqual(1, result.parameters["parameter1"]);
	}

	// NOTE: need to test paranthesis, not, arithmetic operators, and other methods not noted above

}