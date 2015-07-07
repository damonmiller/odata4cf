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
component {

	variables.operatorsMap = {
		"EqExpression": "=",
		"NeExpression": "!=",
		"GtExpression": ">",
		"GeExpression": ">=",
		"LtExpression": "<",
		"LeExpression": "<=",
		"AndExpression": "and",
		"OrExpression": "or",
		"NotExpression": "not",
		"StartsWithMethodCallExpression": "like",
		"EndsWithMethodCallExpression": "like",
		"SubstringOfMethodCallExpression": "like"
	};

	public string function version() {
		return "1.1.0a";
	}

	public struct function parseFilter(required string filter, allowed="none") {
		// empty string do not parse by OData
		if (len(trim(arguments.filter))) {
			resetParameterCount();
			return parseODataFilter(createObject("java", "org.odata4j.producer.resources.OptionsQueryParser").parseFilter(javaCast("string", arguments.filter)), arguments.allowed);
		}
		return {
			"sql": "",
			"parameters": {}
		};
	}

	private struct function parseODataFilter(required filter, required allowed) {
		var methodName = arguments.filter.toString();

		// look for a method to handle this expression
		if (structKeyExists(variables, methodName)) {
			var method = variables[methodName];
			var results = method(arguments.filter, arguments.allowed);
			var sb = createObject("java", "java.lang.StringBuilder").init();
			if (structKeyExists(results, "parsed")) {
				hasSQL = false;
				arrayEach(results.parsed, function(result, i) {
					if (structKeyExists(result, "allowed") && result.allowed) {
						// if we hit and/or as first SQL to include, we need to skip it
						if (!hasSQL && result.method == "handleAndOrOperators") {
							result.allowed = false;
							continue;
						}
						sb.append(" " & result["sql"]);
						hasSQL = true;
					}
				});
				results["sql"] = trim(sb.toString());
			}
			return results;
		}

		UnhandledExpression("Could not convert expression to SQL.", "Type '" & methodName & "' unaccounted for.");
	}

	/* BEGIN Expression handlers */

	// eq
	private function EqExpression(required filter, required allowed) {
		return handleGenericOperator(arguments.filter, arguments.allowed);
	}

	// ne
	private function NeExpression(required filter, required allowed) {
		return handleGenericOperator(arguments.filter, arguments.allowed);
	}

	// gt
	private function GtExpression(required filter, required allowed) {
		return handleGenericOperator(arguments.filter, arguments.allowed);
	}

	// ge
	private function GeExpression(required filter, required allowed) {
		return handleGenericOperator(arguments.filter, arguments.allowed);
	}

	// lt
	private function LtExpression(required filter, required allowed) {
		return handleGenericOperator(arguments.filter, arguments.allowed);
	}

	// le
	private function LeExpression(required filter, required allowed) {
		return handleGenericOperator(arguments.filter, arguments.allowed);
	}

	// startswith(col, val)
	private function StartsWithMethodCallExpression(required filter, required allowed) {
		return handleLikeOperator(arguments.filter, arguments.allowed);
	}

	// endswith(col, val)
	private function EndsWithMethodCallExpression(required filter, required allowed) {
		return handleLikeOperator(arguments.filter, arguments.allowed);
	}

	// substringof(val, col)
	private function SubstringOfMethodCallExpression(required filter, required allowed) {
		return handleLikeOperator(arguments.filter, arguments.allowed);
	}

	// and
	private function AndExpression(required filter, required allowed) {
		return handleAndOrOperators(arguments.filter, arguments.allowed);
	}

	// or
	private function OrExpression(required filter, required allowed) {
		return handleAndOrOperators(arguments.filter, arguments.allowed);
	}

	// -unhandled-
	private void function UnhandledExpression(required string message, required string detail) {
		// how should we handle this?  log it? throw an error/abort?
		throw(type="org.odata.errors.UnhandledExpression", message=arguments.message, detail=arguments.detail);
		abort;
	}

	/* END Expression handlers */

	private function handleGenericOperator(required filter, required allowed) {
		var operator = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();
		var params = {};

		if (arguments.filter.getLHS().toString() == "EntitySimpleProperty") {
			var columnName = arguments.filter.getLHS().getPropertyName();
			var columnValue = wrapInParameterCount(columnName);
			sql.append(columnName & variables.operatorsMap[operator] & ":" & columnValue);
			params[columnValue] = arguments.filter.getRHS().getValue();

			return {
				"method": "handleGenericOperator",
				"columnName": columnName,
				"columnValue": ":" & columnValue,
				"operator": variables.operatorsMap[operator],
				"sql": sql.toString(),
				"parameters": params,
				"allowed": (isArray(arguments.allowed) ? true : false) ? isParameterAllowed(arguments.allowed, columnName) : true
			};
		}

		UnhandledExpression("Could not convert expression to SQL.", "Type '" & arguments.filter.getLHS().toString() & "' unaccounted for.");
	}

	private function handleLikeOperator(required filter, required allowed) {
		var operator = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();
		var params = {};

		var columnName = arguments.filter.getTarget().getPropertyName();
		var columnValue = wrapInParameterCount(columnName);
		sql.append(columnName & " like :" & columnValue);
		if (operator == "StartsWithMethodCallExpression") {
			// startswith converts to 'LIKE value%'
			params[columnValue] = arguments.filter.getValue().getValue() & "%";
		}
		else if (operator == "EndsWithMethodCallExpression") {
			// endswith converts to 'LIKE %value'
			params[columnValue] = "%" & arguments.filter.getValue().getValue();
		}
		else if (operator == "SubstringOfMethodCallExpression") {
			// substringof converts to 'LIKE %value%'
			params[columnValue] = "%" & arguments.filter.getValue().getValue() & "%";
		}

		return {
			"method": "handleLikeOperator",
			"columnName": columnName,
			"columnValue": ":" & columnValue,
			"operator": variables.operatorsMap[operator],
			"sql": sql.toString(),
			"parameters": params,
			"allowed": (isArray(arguments.allowed) ? true : false) ? isParameterAllowed(arguments.allowed, columnName) : true
		};
	}

	private function handleAndOrOperators(required filter, required allowed) {
		var parsed = [];
		var operator = arguments.filter.toString();
		var sql = createObject("java", "java.lang.StringBuilder").init();
		var params = {};

		// recursively call method passing LHS object
		var lResult = parseODataFilter(arguments.filter.getLHS(), arguments.allowed);
		if (lResult.allowed) {
			// add returned SQL to our SQL
			sql.append(lResult.sql);
			// merge parameters together
			params.putAll(lResult.parameters);
		}
		arrayAppend(parsed, lResult);

		// recursively call method passing RHS object
		var rResult = parseODataFilter(arguments.filter.getRHS(), arguments.allowed);

		if (structKeyExists(rResult, "allowed")) {
			arrayAppend(parsed, {
				"method": "handleAndOrOperators",
				"allowed": rResult.allowed,
				"sql": variables.operatorsMap[operator]
			});
			if (rResult.allowed) {
				// merge parameters together
				params.putAll(rResult.parameters);
				structDelete(rResult, "parameters");
			}
		}
		else if (structKeyExists(rResult, "parsed") && isArray(rResult.parsed)) {
			arrayAppend(parsed, {
				"method": "handleAndOrOperators",
				"allowed": rResult.parsed[1].allowed,
				"sql": variables.operatorsMap[operator]
			});
			// merge parameters together
			params.putAll(rResult.parameters);
			structDelete(rResult, "parameters");
			// merge parsed together
			parsed.addAll(rResult.parsed);
			structDelete(rResult, "parsed");
		}

		if (structKeyExists(rResult, "method")) {
			arrayAppend(parsed, rResult);
		}

		return {
			"parameters": params,
			"parsed": parsed
		};
	}

	private string function wrapInParameterCount(required string parameterName) {
		return arguments.parameterName & ++variables.parameterCount;
	}

	private void function resetParameterCount() {
		variables.parameterCount = 0;
	}

	private boolean function isParameterAllowed(required array allowed, required string parameterName) {
		if (arrayFind(arguments.allowed, arguments.parameterName)) {
			return true;
		}
		return false;
	}

}