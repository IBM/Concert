# ConcertDef JSON Schema v1.0.2

ConcertDef JSON Schema is a `JSON Schema` based representation of the Concert-defined data model for enabling generation of `Application 360 Insights`. Three types of ConcertDef v1.0.2 SBOM files can be formatted per this Schema, namely, `build`, `deploy`, and `application` SBOMs. To facilitate understanding and using the Schema, three sub-schemas are provided for each type of ConcertDef SBOM files.  The sub-schema filenames end with `-build.json`, `-deploy.json`, and `-app.json`, respectively.  A developer guide document is included in this folder as well.

The tool `check-jsonschema` can be used to check for **syntax** errors of a ConcertDef file formatted in JSON.  Home page of the tool is at the URL below.
`https://github.com/python-jsonschema/check-jsonschema`

For example, the command below uses the ConcertDef JSON Schema file `ConcertDef-1.0.2-Schema.json` to check the **syntax** of the JSON-formatted ConcertDef build file `component-build.json`.  **Semantic** checking (e.g., value validation for property names and values) will be performed by the Concert Service in use and is beyond the scope of schema-based **syntax** checking.

`check-jsonschema --schemafile ConcertDef-1.0.2-Schema.json component-build.json`

The schema can also be used to check for the syntax errors and/or to facilitate schema-based editing of ConcertDef JSON files from within a tool like Microsoft `vscode`.  A good how-do summary is available at: https://frontaid.io/blog/json-schema-vscode/
