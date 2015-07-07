<!---
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
--->
<cfscript>
	rc.pageTitle = "OData4CF Home";
	rc.showTitle = false;
</cfscript>
<cfoutput>
	<div class="page-header" style="border: 0 none;"></div>

	<div class="jumbotron">
		<h1>OData4CF</h1>
		<p>OData for ColdFusion and Railo Applications</p>
	</div>

	<div class="row">
		<!---<div class="col-md-3">
			<h2>Documentation</h2>
			<p>Compatibility information, setup, tutorials, API reference, and links to latest download are available here: <a href="https://damonmiller.github.io/odata4cf/">http://damonmiller.github.io/odata4cf/</a></p>
		</div>--->
		<div class="col-md-4">
			<h2>Release Notes</h2>
			<p>Information on bug fixes and improvements for each release are available here: <a href="https://github.com/damonmiller/odata4cf/releases">https://github.com/damonmiller/odata4cf/releases</a></p>
		</div>
		<div class="col-md-4">
			<h2>Issues</h2>
			<p>You can find known issues or report new issues here: <a href="https://github.com/damonmiller/odata4cf/issues">https://github.com/damonmiller/odata4cf/issues</a></p>
		</div>
		<div class="col-md-4">
			<h3>Tests <small class="label label-info">Lucee 4.5+</small></h3>
			<p>The OData4CF MXUnit TestSuite is included and can be run locally for you here: <a href="../test/TestSuite.cfm">Click Here</a>.</p>
		</div>
	</div>

</cfoutput>