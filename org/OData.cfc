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
		"NotExpression": "not"
	};

	public string function version() {
		return "1.0.1a";
	}

	public struct function parseFilter(required string filter) {
		// empty string do not parse by OData
		if (len(trim(arguments.filter))) {
			resetParameterCount();
			return parseODataFilter(createObject("java", "org.odata4j.producer.resources.OptionsQueryParser").parseFilter(javaCast("string", arguments.filter)));
		}
		return {
			"sql": "",
			"parameters": {}
		};
	}

	private function parseODataFilter(required filter) {
		var result = createObject("java", "java.lang.StringBuilder").init();
		var params = {};
		var filterType = arguments.filter.toString();

		if (listFind("EqExpression,NeExpression,GtExpression,GeExpression,LtExpression,LeExpression", filterType)) {
			if (arguments.filter.getLHS().toString() == "EntitySimpleProperty") {
				var queryPropertyName = arguments.filter.getLHS().getPropertyName();
				var propertyName = wrapInParameterCount(queryPropertyName);
				result.append(queryPropertyName & variables.operatorsMap[filterType] & ":" & propertyName);
				params[propertyName] = arguments.filter.getRHS().getValue();
			}
			else {
				unhandledExpression("Could not convert expression to SQL.", "Type '" & arguments.filter.getLHS().toString() & "' unaccounted for.");
			}
		}
		else if (listFind("StartsWithMethodCallExpression,EndsWithMethodCallExpression,SubstringOfMethodCallExpression", filterType)) {
			var queryPropertyName = arguments.filter.getTarget().getPropertyName();
			var propertyName = wrapInParameterCount(queryPropertyName);
			result.append(queryPropertyName & " like :" & propertyName);
			if (filterType == "StartsWithMethodCallExpression") {
				// startswith converts to 'LIKE value%'
				params[propertyName] = arguments.filter.getValue().getValue() & "%";
			}
			else if (filterType == "EndsWithMethodCallExpression") {
				// endswith converts to 'LIKE %value'
				params[propertyName] = "%" & arguments.filter.getValue().getValue();
			}
			else if (filterType == "SubstringOfMethodCallExpression") {
				// substringof converts to 'LIKE %value%'
				params[propertyName] = "%" & arguments.filter.getValue().getValue() & "%";
			}
		}
		else if (listFind("AndExpression,OrExpression", filterType)) {
			// recursively call method passing LHS object
			var lResult = parseODataFilter(arguments.filter.getLHS());
			// add returned SQL to our SQL
			result.append(lResult.sql);
			// merge parameters together
			params.putAll(lResult.parameters);

			// recursively call method passing RHS object
			var rResult = parseODataFilter(arguments.filter.getRHS());
			// add returned SQL to our SQL with proper operator
			result.append(" " & variables.operatorsMap[filterType] & " " & rResult.sql);
			// merge parameters together
			params.putAll(rResult.parameters);
		}
		else {
			unhandledExpression("Could not convert expression to SQL.", "Type '" & filterType & "' unaccounted for.");
		}

		return {
			"sql": result.toString(),
			"parameters": params
		};
	}

	private string function wrapInParameterCount(required string parameterName) {
		return arguments.parameterName & ++variables.parameterCount;
	}

	private void function resetParameterCount() {
		variables.parameterCount = 0;
	}

	private void function unhandledExpression(required string message, required string detail) {
		// how should we handle this?  log it? throw an error/abort?
		throw(type="org.odata.errors.UnhandledExpression", message=arguments.message, detail=arguments.detail);
		abort;
	}

}