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
component {

	variables.ODataTypeMap = {
		"EqExpression": "=",
		"AndExpression": "AND",
		"OrExpression": "OR",
		"LtExpression": "<",
		"GtExpression": ">",
		"GeExpression": ">=",
		"LeExpression": "<=",
		"NeExpression": "<>",
		"EndsWithMethodCallExpression": "LIKE",
		"StartsWithMethodCallExpression": "LIKE",
		"SubstringOfMethodCallExpression": "LIKE",
		"LengthMethodCallExpression": "LEN",
		"IndexOfMethodCallExpression": "CHARINDEX",
		"ReplaceMethodCallExpression": "REPLACE",
		"SubstringMethodCallExpression": "SUBSTRING",
		"ToLowerMethodCallExpression": "LOWER",
		"ToUpperMethodCallExpression": "UPPER",
		"TrimMethodCallExpression": "TRIM",
		"ConcatMethodCallExpression": "CONCAT",
		"DayMethodCallExpression": "DAY",
		"MonthMethodCallExpression": "MONTH",
		"YearMethodCallExpression": "YEAR",
		"HourMethodCallExpression": "HOUR",
		"MinuteMethodCallExpression": "MINUTE",
		"SecondMethodCallExpression": "SECOND",
		"RoundMethodCallExpression": "ROUND",
		"FloorMethodCallExpression": "FLOOR",
		"CeilingMethodCallExpression": "CEILING"
	};

	public string function version() {
		return "1.2.0";
	}

	public struct function parseFilter(required string filter, allowed="none") {
		// OData4J will not parse empty strings
		if (!len(trim(arguments.filter))) return {"SQL": "", "parameters": {}};

		resetParameterCount();
		var result = parseODataFilter(createObject("java", "org.odata4j.producer.resources.OptionsQueryParser").parseFilter(javaCast("string", arguments.filter)), arguments.allowed);
		return result;
	}

	private struct function parseODataFilter(required filter, required allowed) {
		var ODataType = arguments.filter.toString();

		// error if there is no expression handler found
		if (!structKeyExists(variables, ODataType)) {
			_unhandled("Could not convert expression to SQL.", "Type '" & ODataType & "' unaccounted for.");
		}

		var method = variables[ODataType];
		var results = method(arguments.filter, arguments.allowed);

		if (structKeyExists(results, "allowed") && !results.allowed) {
			results["SQL"] = "";
			results["parameters"] = {};
		}
		else if (structKeyExists(results, "parsed")) {
			var sb = createObject("java", "java.lang.StringBuilder").init();
			var hasSQL = false;
			arrayEach(results.parsed, function(result, i) {
				if (structKeyExists(result, "allowed") && result.allowed) {
					// if we hit and/or as first SQL to include, we need to skip it
					if (!hasSQL && listFind("AndExpression,OrExpression", result["ODataType"])) {
						continue;
					}
					sb.append(" " & result["SQL"]);
					hasSQL = true;
				}
			});
			results["SQL"] = trim(sb.toString());
		}
		return results;
	}

	/* BEGIN: Expression handlers */

	// AddExpression (BinaryCommonExpression)
	private function AddExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// TODO: AggregateAllFunction (AggregateBoolFunction, BoolCommonExpression)
	// TODO: AggregateAnyFunction (AggregateBoolFunction, BoolCommonExpression)

	// AndExpression (BinaryBoolCommonExpression, BoolCommonExpression)
	private function AndExpression(required filter, required allowed) {
		return BinaryBoolCommonExpression(arguments.filter, arguments.allowed);
	}

	// BinaryBoolCommonExpression
	private function BinaryBoolCommonExpression(required filter, required allowed) {
		var parsed = [];
		var ODataType = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();
		var params = {};

		// recursively call method passing LHS object
		var lhs = parseODataFilter(arguments.filter.getLHS(), arguments.allowed);
		if (lhs.allowed) {
			// add returned SQL to our SQL
			sql.append(lhs.sql);
			// merge parameters together
			params.putAll(lhs.parameters);
		}
		arrayAppend(parsed, lhs);

		// recursively call method passing RHS object
		var rhs = parseODataFilter(arguments.filter.getRHS(), arguments.allowed);

		if (structKeyExists(rhs, "allowed")) {
			arrayAppend(parsed, {
				"ODataType": ODataType,
				"allowed": rhs.allowed,
				"SQL": variables.ODataTypeMap[ODataType]
			});
			if (rhs.allowed) {
				// merge parameters together
				params.putAll(rhs.parameters);
				structDelete(rhs, "parameters");
			}
		}
		else if (structKeyExists(rhs, "parsed") && isArray(rhs.parsed)) {
			arrayAppend(parsed, {
				"ODataType": ODataType,
				"allowed": rhs.parsed[1].allowed,
				"SQL": variables.ODataTypeMap[ODataType]
			});
			// merge parameters together
			params.putAll(rhs.parameters);
			structDelete(rhs, "parameters");
			// merge parsed together
			parsed.addAll(rhs.parsed);
			structDelete(rhs, "parsed");
		}

		if (structKeyExists(rhs, "ODataType")) {
			arrayAppend(parsed, rhs);
		}

		return {
			"parameters": params,
			"parsed": parsed
		};
	}

	// BinaryCommonExpression
	private function BinaryCommonExpression(required filter, required allowed) {
		var ODataType = arguments.filter.getLHS().toString();

		// error if there is no expression handler found
		if (!structKeyExists(variables, ODataType)) {
			_unhandled("Could not convert expression to SQL.", "Type '" & ODataType & "' unaccounted for.");
		}

		var method = variables[ODataType];
		return method(arguments.filter, arguments.allowed);
	}

	// BinaryLiteral (LiteralExpression)
	private function BinaryLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// BooleanLiteral (BoolCommonExpression, LiteralExpression)
	private function BooleanLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// BoolMethodExpression (BoolCommonExpression, MethodCallExpression)
	private function BoolMethodExpression(required filter, required allowed) {
		var ODataType = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();

		var lhs = CommonExpression(arguments.filter.getTarget(), arguments.allowed);
		var rhs = CommonExpression(arguments.filter.getValue(), arguments.allowed);
		var parameters = _getParameters(lhs, rhs);

		sql.append(_getSQL(lhs) & " " & variables.ODataTypeMap[ODataType] & " " & _getSQL(rhs));

		// add % to parameter value for LIKE only
		for (var parameter in parameters) {
			if (ODataType == "EndsWithMethodCallExpression")			parameters[parameter] = "%" & parameters[parameter];
			else if (ODataType == "StartsWithMethodCallExpression")		parameters[parameter] = parameters[parameter] & "%";
			else if (ODataType == "SubstringOfMethodCallExpression")	parameters[parameter] = "%" & parameters[parameter] & "%";
		}

		return {
			"ODataType": ODataType,
			"LHS": lhs,
			"RHS": rhs,
			"SQLValue": variables.ODataTypeMap[ODataType],
			"SQL": sql.toString(),
			"parameters": parameters,
			"allowed": _isParameterAllowed(arguments.allowed, lhs, rhs)
		};
	}

	// BoolParenExpression (BoolCommonExpression)
	private function BoolParenExpression(required filter, required allowed) {
		var ODataType = arguments.filter.toString();
		var result = parseODataFilter(arguments.filter.getExpression(), arguments.allowed);
		arrayPrepend(result["parsed"], {
			"allowed": true,
			"ODataType": ODataType,
			"SQLValue": "(",
			"SQL": "("
		});
		arrayAppend(result["parsed"], {
			"allowed": true,
			"ODataType": ODataType,
			"SQLValue": ")",
			"SQL": ")"
		});

		return result;
	}

	// ByteLiteral (LiteralExpression)
	private function ByteLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// TODO: CastExpression

	// CeilingMethodCallExpression (MethodCallExpression)
	private function CeilingMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	private array function CommonExpression(required filter, required allowed) {
		// NOTE: there is a bug with TRIM.toString() where it returns LENGTH class name instead
		//var ODataType = arguments.filter.toString();
		var ODataType = replace(listLast(arguments.filter.getClass().getName(), "$"), "Impl", "");
		var result = [];

		// TODO: look to grab super class and use it to make the below much simpler/cleaner

		if (ODataType == "BooleanLiteral") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"ODataValue": arguments.filter.getValue(),
				"SQLType": "boolean",
				"SQLParameter": getBindingParameter(),
				"SQLValue": arguments.filter.getValue()
			});
		}
		else if (ODataType == "CeilingMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "ConcatMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getLHS(), arguments.allowed)[1],
					CommonExpression(arguments.filter.getRHS(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "DayMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}

		else if (ODataType == "StringLiteral") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"ODataValue": arguments.filter.getValue(),
				"SQLType": "string",
				"SQLParameter": getBindingParameter(),
				"SQLValue": arguments.filter.getValue()
			});
		}
		else if (ODataType == "IntegralLiteral") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"ODataValue": arguments.filter.getValue(),
				"SQLType": "integer",
				"SQLParameter": getBindingParameter(),
				"SQLValue": arguments.filter.getValue()
			});
		}
		else if (ODataType == "NullLiteral") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"ODataValue": "NULL",
				"SQLType": javaCast("null", ""),
				"SQLParameter": getBindingParameter(),
				"SQLValue": javaCast("null", "")
			});
		}
		else if (ODataType == "EntitySimpleProperty") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"ODataValue": arguments.filter.getPropertyName(),
				"SQLType": "columnName",
				"SQLParameter": javaCast("null", ""),
				"SQLValue": arguments.filter.getPropertyName()
			});
		}
		else if (ODataType == "LengthMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "IndexOfMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getValue(), arguments.allowed)[1],
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "ReplaceMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1],
					CommonExpression(arguments.filter.getFind(), arguments.allowed)[1],
					CommonExpression(arguments.filter.getReplace(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "SubstringMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1],
					CommonExpression(arguments.filter.getStart(), arguments.allowed)[1],
					isNull(arguments.filter.getLength()) ? javaCast("null", "") : CommonExpression(arguments.filter.getLength(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "ToLowerMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "ToUpperMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "TrimMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "MonthMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "YearMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "HourMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "MinuteMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "SecondMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "RoundMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else if (ODataType == "FloorMethodCallExpression") {
			arrayAppend(result, {
				"ODataType": ODataType,
				"SQLFunction": variables.ODataTypeMap[ODataType],
				"SQLArguments": [
					CommonExpression(arguments.filter.getTarget(), arguments.allowed)[1]
				]
			});
		}
		else {
			_unhandled("Could not convert expression to SQL.", "Type '" & ODataType & "' unaccounted for.");
		}

		return result;
	}

	// ConcatMethodCallExpression (MethodCallExpression)
	private function ConcatMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// DateTimeLiteral (LiteralExpression)
	private function DateTimeLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// DateTimeOffsetLiteral (LiteralExpression)
	private function DateTimeOffsetLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// DayMethodCallExpression (MethodCallExpression)
	private function DayMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// DecimalLiteral (LiteralExpression)
	private function DecimalLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// DivExpression (BinaryCommonExpression)
	private function DivExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// DoubleLiteral (LiteralExpression)
	private function DoubleLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// EndsWithMethodCallExpression (BoolCommonExpression, BoolMethodExpression, MethodCallExpression)
	private function EndsWithMethodCallExpression(required filter, required allowed) {
		return BoolMethodExpression(arguments.filter, arguments.allowed);
	}

	// EntitySimpleProperty
	private function EntitySimpleProperty(required filter, required allowed) {
		var ODataType = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();

		var lhs = CommonExpression(arguments.filter.getLHS(), arguments.allowed);
		var rhs = CommonExpression(arguments.filter.getRHS(), arguments.allowed);
		var parameters = _getParameters(lhs, rhs);

		sql.append(_getSQL(lhs) & " " & variables.ODataTypeMap[ODataType] & " " & _getSQL(rhs));

		return {
			"ODataType": ODataType,
			"LHS": lhs,
			"RHS": rhs,
			"SQLValue": variables.ODataTypeMap[ODataType],
			"SQL": sql.toString(),
			"parameters": parameters,
			"allowed": _isParameterAllowed(arguments.allowed, lhs, rhs)
		};
	}

	// EqExpression (BinaryCommonExpression, BoolCommonExpression)
	private function EqExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// FloorMethodCallExpression (MethodCallExpression)
	private function FloorMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// GeExpression (BinaryCommonExpression, BoolCommonExpression)
	private function GeExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// GtExpression (BinaryCommonExpression, BoolCommonExpression)
	private function GtExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// GuidLiteral (LiteralExpression)
	private function GuidLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// HourMethodCallExpression (MethodCallExpression)
	private function HourMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// IndexOfMethodCallExpression (MethodCallExpression)
	private function IndexOfMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// Int64Literal (LiteralExpression)
	private function Int64Literal(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// IntegralLiteral (LiteralExpression)
	private function IntegralLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// TODO: IsofExpression (BoolCommonExpression)

	// LeExpression (BinaryCommonExpression, BoolCommonExpression)
	private function LeExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// LengthMethodCallExpression (MethodCallExpression)
	private function LengthMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// LiteralExpression
	private function LiteralExpression(required filter, required allowed) {
		var ODataType = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();

		var lhs = CommonExpression(arguments.filter.getLHS(), arguments.allowed);
		var rhs = CommonExpression(arguments.filter.getRHS(), arguments.allowed);
		var parameters = _getParameters(lhs, rhs);

		sql.append(_getSQL(lhs) & " " & variables.ODataTypeMap[ODataType] & " " & _getSQL(rhs));

		return {
			"ODataType": ODataType,
			"LHS": lhs,
			"RHS": rhs,
			"SQLValue": variables.ODataTypeMap[ODataType],
			"SQL": sql.toString(),
			"parameters": parameters,
			"allowed": _isParameterAllowed(arguments.allowed, lhs, rhs)
		};
	}

	// LtExpression (BinaryCommonExpression, BoolCommonExpression)
	private function LtExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// MethodCallExpression
	private function MethodCallExpression(required filter, required allowed) {
		var ODataType = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();

		var lhs = CommonExpression(arguments.filter.getLHS(), arguments.allowed);
		var rhs = CommonExpression(arguments.filter.getRHS(), arguments.allowed);
		var parameters = _getParameters(lhs, rhs);

		sql.append(_getSQL(lhs) & " " & variables.ODataTypeMap[ODataType] & " " & _getSQL(rhs));

		return {
			"ODataType": ODataType,
			"LHS": lhs,
			"RHS": rhs,
			"SQLValue": variables.ODataTypeMap[ODataType],
			"SQL": sql.toString(),
			"parameters": parameters,
			"allowed": _isParameterAllowed(arguments.allowed, lhs, rhs)
		};
	}

	// MinuteMethodCallExpression (MethodCallExpression)
	private function MinuteMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// ModExpression (BinaryCommonExpression)
	private function ModExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// MonthMethodCallExpression (MethodCallExpression)
	private function MonthMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// MulExpression (BinaryCommonExpression)
	private function MulExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// NeExpression (BinaryCommonExpression, BoolCommonExpression)
	private function NeExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// TODO: NegateExpression (BoolCommonExpression)
	// TODO: NotExpression (BoolCommonExpression)

	// NullLiteral (LiteralExpression)
	private function NullLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// OrExpression (BinaryBoolCommonExpression, BoolCommonExpression)
	private function OrExpression(required filter, required allowed) {
		return BinaryBoolCommonExpression(arguments.filter, arguments.allowed);
	}

	// TODO: ParenExpression

	// ReplaceMethodCallExpression (MethodCallExpression)
	private function ReplaceMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// RoundMethodCallExpression (MethodCallExpression)
	private function RoundMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// SByteLiteral (LiteralExpression)
	private function SByteLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// SecondMethodCallExpression (MethodCallExpression)
	private function SecondMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// SingleLiteral (LiteralExpression)
	private function SingleLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// StartsWithMethodCallExpression (BoolCommonExpression, BoolMethodExpression, MethodCallExpression)
	private function StartsWithMethodCallExpression(required filter, required allowed) {
		return BoolMethodExpression(arguments.filter, arguments.allowed);
	}

	// StringLiteral (LiteralExpression)
	private function StringLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// SubExpression (BinaryCommonExpression)
	private function SubExpression(required filter, required allowed) {
		return BinaryCommonExpression(arguments.filter, arguments.allowed);
	}

	// SubstringMethodCallExpression (MethodCallExpression)
	private function SubstringMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// SubstringOfMethodCallExpression (BoolCommonExpression, BoolMethodExpression, MethodCallExpression)
	private function SubstringOfMethodCallExpression(required filter, required allowed) {
		return BoolMethodExpression(arguments.filter, arguments.allowed);
	}

	// TimeLiteral (LiteralExpression)
	private function TimeLiteral(required filter, required allowed) {
		return LiteralExpression(arguments.filter, arguments.allowed);
	}

	// ToLowerMethodCallExpression (MethodCallExpression)
	private function ToLowerMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// ToUpperMethodCallExpression (MethodCallExpression)
	private function ToUpperMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// TrimMethodCallExpression (MethodCallExpression)
	private function TrimMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	// YearMethodCallExpression (MethodCallExpression)
	private function YearMethodCallExpression(required filter, required allowed) {
		return MethodCallExpression(arguments.filter, arguments.allowed);
	}

	/* END: Expression handlers */

	/* miscellaneous private methods */

	private void function _unhandled(required string message, required string detail) {
		// how should we handle this?  log it? throw an error/abort?
		throw(type="org.odata.errors.UnhandledExpression", message=arguments.message, detail=arguments.detail);
		abort;
	}

	private function _getParameters(required lhs, required rhs) {
		var result = _getParameter(arguments.lhs);
		result.putAll(_getParameter(arguments.rhs));
		return result;
	}

	private function _getParameter(required property) {
		var result = {};

		if (isArray(arguments.property)) {
			for (var prop in arguments.property) {
				if (isNull(prop)) continue;
				var nestedResult = _getParameter(prop);
				if (!isNull(nestedResult)) result.putAll(nestedResult);
			}
			return result;
		}

		// grab parameters from SQLArguments
		if (structKeyExists(arguments.property, "SQLFunction")) {
			var nestedResult = _getParameter(arguments.property.SQLArguments);
			if (!isNull(nestedResult)) result.putAll(nestedResult);
			return result;
		}

		// skip if no parameter required
		if (!structKeyExists(arguments.property, "SQLParameter")) {
			return;
		}

		// return parameter/value
		result[arguments.property.SQLParameter] = structKeyExists(arguments.property, "SQLValue") ? arguments.property.SQLValue : javaCast("null", "");
		return result;
	}

	private string function _getSQL(required property) {
		var result = createObject("java", "java.lang.StringBuilder").init();

		if (isArray(arguments.property)) {
			var arrLen = arrayLen(arguments.property);
			for (var i=1; i<=arrLen; i++) {
				if (isNull(arguments.property[i])) continue;
				if (i>1) result.append(" , ");
				result.append(_getSQL(arguments.property[i]));
			}
			return result.toString();
		}

		// return SQL function
		if (structKeyExists(arguments.property, "SQLFunction")) {
			// MSSQL does not support TRIM() so use LTRIM(RTRIM()) instead
			if (arguments.property.SQLFunction == "TRIM") {
				result.append("LTRIM(RTRIM( ");
				result.append(_getSQL(arguments.property.SQLArguments));
				result.append(" ))");
			}
			else {
				result.append(arguments.property.SQLFunction);
				result.append("( ");
				result.append(_getSQL(arguments.property.SQLArguments));
				result.append(" )");
			}
			return result.toString();
		}

		// return value as-is
		if (!structKeyExists(arguments.property, "SQLParameter")) {
			result.append(arguments.property.SQLValue);
			return result.toString();
		}

		// return parameter binding
		result.append(":" & arguments.property.SQLParameter);
		return result.toString();
	}

	private boolean function _isParameterAllowed(required allowed, required lhs, required rhs) {
		if (!isArray(arguments.allowed)) return true;

		// we need to search both lhs and rhs for ALL columnNames
		var cols = arrayFilter(arguments.lhs, function(elm) {
			if (elm.SQLType == "columnName") return true;
			return false;
		});
		cols.addAll(arrayFilter(arguments.rhs, function(elm) {
			if (elm.SQLType == "columnName") return true;
			return false;
		}));

		// if any columnNames are not allowed the entire statement is not allowed
		var arrAllowed = arguments.allowed;
		var index = arrayFind(cols, function(elm) {
			if (arrayFindNoCase(arrAllowed, elm.SQLValue)) return true;
			return false;
		});

		return index > 0 ? true : false;
	}

	private string function getBindingParameter() {
		return "parameter" & ++variables.parameterCount;
	}

	private void function resetParameterCount() {
		variables.parameterCount = 0;
	}

}