# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.4] - 2023-08-11
### Fixed
- Incorrect JSON schema type for `secretName` in ingress configuration fixed to type `"string"`

## [3.2.3] - 2023-08-10
### Changed
- Changed default behaviour of Data App deployment strategy
- Allow configuration of deployment strategy for all (core container, admin UI, data apps/helpers) deployments

## [3.2.2] - 2023-04-23
### Fixed
- Updated `values.schema.json`
- Updated default settings regarding workflow and orchestration manager

### Added
- `binaryData` support for container configMaps

## [3.2.1] - 2023-03-29
### Fixed
- Default CPU resource limits for core container and data apps
- Default core container UI image

## [3.2.0] - 2023-03-01
### Fixed
- Optionally expose Core Container API via ingress
- Issue with rendering inline configmap templates of data apps due to missing object separators

## [3.1.1] - 2022-08-26
### Fixed
- Pull secret template handling
- JSON Schema fields:
  - Core container accessUrl

### Added
- JSON Schema fields: 
  - K8s probes
  - data app secrets/configMaps
  - data app TTY

## [3.1.0] - 2022-08-24
### Added
- JSON Schema for values for pre-deploy validation
