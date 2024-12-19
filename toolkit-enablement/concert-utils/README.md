# concert-utils

This repo includes a set of Concert utility scripts that facilitate exploiting the capabilities of a Concert Toolkit image.  The scripts are organized in different directories in terms of the script exploitation context.

Scripts in the `helpers` directory are described in `ConcertUtils_Guide.md`.  All types of Concert supported files can be uploaded to a Concert service instance via `concert_upload.sh`. For each type of Concert supported files, there is a script that converts a YAML-formated ConcertDef file to a JSON-formatted one.  All the scripts run a Concert Toolkit image to complete their respecitve tasks.

The `concertdef_schema` directory includes the JSON Schema based specification of ConcertDef Schema v1.0.2 and the developer guide for the ConcertDef Schema.  The Schema is used for formatting three types of ConcertDef v1.0.2 SBOM files, namely, `build`, `deploy`, and `application` SBOMs.  The data uploaded to Concert via those ConcertDef SBOM files enable the generation of `Application 360 Insights` despite enterprise data silos.
