# CHANGELOG

## 1.2.1 - 2019-06-26

  - Fixed bug in Manual Chunking that could result in larger batches.
  - Added IOError to the types of errors that are retried.
  - Removed circular reference and warning about it.

## 1.2.0 - 2019-06-14

  - Added an include_deleted flag to perform a queryAll operation.
  - Disabled explicit GZIP encoding to work with the latest versions of HTTParty.
  - Added a retry for requests to recover from Net::ReadTimeout errors.

## 1.1.1 - 2018-11-26

  - Reimplemented ManualChunkingQuery using CSV batch results.
  - Changed sleeping and timeout error to only occur when no new results appear.
  - Added more log info messages with regards to JSON parsing and yielding results.

## 1.1.0 - 2018-11-06

  - Added ManualChunkingQuery, which implements chunking within the gem for any Salesforce field.

## 1.0.0 - 2018-09-12

  - Initial Open Source Release
