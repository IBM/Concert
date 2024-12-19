# Toolkit Enablement

The repositories **concert-utils** and **concert-sample** provide supplementary information to the IBM Concert Toolkit.

### concert-utils
This is a collection of helper scripts that uses the IBM Concert Toolkit in order to:

* Create application SBOMs per the ConcertDef format
* Create build SBOMs per the ConcertDef format
* Create deploy SBOMs per the ConcertDef format
* Generate package SBOMs in CycloneDX format, given code repositories
* Generate package SBOMs in CycloneDX format, given container images 

### concert-sample
This leverages **concert-utils** (and thus the IBM Concert Toolkit) for a sample application to showcase end-to-end integration with Concert. It does the following:

* Builds the sample application container image
* Sets up a variables file for SBOM generation and metadata
* Simulates the application definition
    * Generates the application SBOM using the variables file
    * Uploads the application SBOM to Concert
* Simulates the CI pipeline
    * Generates the build SBOM using the variables file
    * Generates the CycloneDX package SBOM for the code repository
    * Uploads the build and CycloneDX package SBOMs to Concert
* Simulates the CD pipeline
    * Generates the deploy SBOM using the variables file
    * Uploads the deploy SBOM to Concert
