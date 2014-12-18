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

	public struct function parseFilter(required string filter) {
		// the filter string must have a length for OData
		if (len(trim(arguments.filter))) {

			var result = createObject("java", "java.lang.StringBuilder").init();
			var params = {};

			var parsedFilter = createObject("java", "org.odata4j.producer.resources.OptionsQueryParser").parseFilter(javaCast("string", arguments.filter));
			var filterType = parsedFilter.toString();

			if (listFind("EqExpression,NeExpression,GtExpression,GeExpression,LtExpression,LeExpression", filterType)) {
				if (parsedFilter.getLHS().toString() == "EntitySimpleProperty") {
					var columnName = parsedFilter.getLHS().getPropertyName();
					result.append(columnName & getOperators()[filterType] & ":" & columnName);
					params[columnName] = parsedFilter.getRHS().getValue();
				}
				else {
					unhandledExpression("Could not convert expression to SQL.", "Type '" & parsedFilter.getLHS().toString() & "' unaccounted for.");
				}
			}
			else if (listFind("StartsWithMethodCallExpression,EndsWithMethodCallExpression,SubstringOfMethodCallExpression", filterType)) {
				var columnName = parsedFilter.getTarget().getPropertyName();
				result.append(columnName & " like :" & columnName);
				if (filterType == "StartsWithMethodCallExpression") {
					// startswith converts to 'LIKE value%'
					params[columnName] = parsedFilter.getValue().getValue() & "%";
				}
				else if (filterType == "EndsWithMethodCallExpression") {
					// endswith converts to 'LIKE %value'
					params[columnName] = "%" & parsedFilter.getValue().getValue();
				}
				else if (filterType == "SubstringOfMethodCallExpression") {
					// substringof converts to 'LIKE %value%'
					params[columnName] = "%" & parsedFilter.getValue().getValue() & "%";
				}
			}
			else if (listFind("AndExpression,OrExpression", filterType)) {
				// recursively call method passing LHS object
				var lResult = parseFilter(parsedFilter.getLHS());
				// add returned SQL to our SQL
				result.append(lResult.result);
				// merge parameters together
				params.putAll(lResult.parameters);

				// recursively call method passing RHS object
				var rResult = parseFilter(parsedFilter.getRHS());
				// add returned SQL to our SQL with proper operator
				result.append(" " & getOperators()[filterType] & " " & rResult.result);
				// merge parameters together
				params.putAll(rResult.parameters);
			}
			else {
				unhandledExpression("Could not convert expression to SQL.", "Type '" & filterType & "' unaccounted for.");
			}

			if (structCount(params)) {
				return {
					"sql": result.toString(),
					"parameters": params
				};
			}
		}

		// however we get to this case ensure we send back correct structure
		return {
			"sql": "",
			"parameters": {}
		};
	}

	private struct function getOperators() {
		return {
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
	}

	private void function unhandledExpression(required string message, required string detail) {
		// how should we handle this?  log it? throw an error/abort?
		throw(type="org.odata.errors.UnhandledExpression", message=arguments.message, detail=arguments.detail);
		abort;
	}


}