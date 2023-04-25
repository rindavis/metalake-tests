# Metadata Lake Integration Tests with Postman

Postman is an API platform that provides the user with an extensive UI for making direct API calls. It includes a number of ease-of-life features. The Postman app is absolutely essential when working on these tests, as the raw test files themselves are considerably more difficult to read. You can download Postman [here](https://www.postman.com/downloads/).

Once test collections have been exported from Postman, you can run these collections outside of the UI using the CLI `newman`. This is what is leveraged for the bash script for end-to-end tests.

## Postman

### Development

A series of API calls can be put together in a collection, which can then be run all at once (each all back-to-back). Integration testing with Postman means determining the correct series of calls for a flow, and then writing corresponding tests for each call.

The tests themselves are written in JavaScript, but Postman provides a few packages that make testing more intuitive. When navigating to the 'Tests' tab for a call, a dialog will provide you with a number of examples of the types of checks you might perform. Postman also provides a [test guide](https://learning.postman.com/docs/writing-scripts/script-references/test-examples/) with many examples. The Postman UI includes an auto-complete and suggestions when writing the code as well.

A test should contain at least a title and an assertion that the correct status code is returned. This might look like:

```
pm.test("Test that OK response is returned", function () {
    postman.setNextRequest(null);
    pm.response.to.have.status(200);
    postman.setNextRequest();
});
```

Note the first and last `setNextRequest` calls which should **always** be included for happy path tests. The current version of Postman will continue a collection even if a call fails rather than bailing. This is usually a problem for integration tests since they depend on one another. For instance, if one call creates a provider and the next deletes it, the first call failing would negatively impact the next - and any remaining - call. Using these methods ensures that execution stops once any call fails. You can also skip some requests altogether by explicitly specifying the next step using the request name (e.g. `postman.setNextRequest("Delete provider");`)

#### Frequently used

There are many different types of assertions and utilities you can use, but a few will be more common. In addition to the response code check above, some include:

##### Simple equality check
`pm.expect(id).to.eq(2)`

##### Equality check for multiple alternatives
`pm.expect(state).to.be.oneOf(["ONE", "TWO"]);`

##### Getting field from response object
`pm.response.json().field`

##### Getting a global variable value/setting a global variable

`pm.globals.get("global_var")`

`pm.globals.set("global_var", "new_value")`

You can reference these outside of the tests (in the path, headers, etc) with `{{global_var}}`. This is essential for many calls. For instance, if you have `POST /providers` followed by `GET /providers/<id>`, you need to capture that id in a global variable in the POST test.

##### Polling job status

This can be accomplished by using a variable as a counter and a combination of `setTimeout(() => {}, timeoutMs)` to wait between calls and `postman.setNextRequest(pm.info.requestId)` to specify that the next API call should be this same one (so you do not need to copy-paste the request over and over again in the collection). You can then use `pm.expect.fail("Failure message")` if your overall time limit is reached or if another failure state occurs.

## End-to-end script

### Development

The CLI for running Postman is `newman`, which must be installed with npm. Supplying newman with the exported collection file will run the collection as you would from the Postman UI. It outputs a descriptive report for each test but can be [customized](https://learning.postman.com/docs/collections/using-newman-cli/newman-options/) even further.

Any `console.log` statement from Postman will be displayed along with the method call in the report. If a collection is meant to be idempotent but there is a failure, you can use these logs to output what will need to be cleaned up (for instance, outputting the id of a provider that was created in case automatic deletion failed).

When adding tests:

- The `usage` dialogue should be updated.
- Every collection should belong to its own function which has a print statement at the beginning and end.
- Every function should call `newman` for that exported collection. Please refer to existing commands and use similar options. This includes `--verbose --reporters cli,json --reporter-json-export <filename>`.
- For errors, please provide a unique non-zero exit code.
- If there is any remaining/future work on a collection, please add a TODO here.
- If credentials or other sensitive info must be provided in the request body, parameterize it and then pass in those values as a global variable instead.

### Usage

Running `./e2e.sh` with no arguments will provide a usage dialogue. The script requires the basic username/password for the DGC instance (which will be used to log in, and after that all endpoints will just use the cookie), the URL for Metadata Lake and the URL for DGC.  The Metadata Lake URL should include the scheme and the path up to `/v1` in the API call. Locally, this may only be `http://localhost:8080`, but for some environments looks more like `https://mdl-beta-sandbox-integration.dev-aws.cp.collibra-ops.com/rest/mdl`. Lastly, the stage should be provided which corresponds to the test collection (or `all`, for every collection) to be run. If that collection requires additional input in the form of global variables, there is an optional `-g` as well. For example:

```
./e2e.sh -h http://localhost:8080 -d https://mdl-beta-sandbox-integration.dev-aws.cp.collibra-ops.com -u <integration user> -p <integration password> -s file-ingest -g aws_id=<aws id for 'dgc-sr-test'> -g aws_secret=<aws key for 'dgc-sr-test'>
```
