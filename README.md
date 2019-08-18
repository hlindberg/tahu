# tahu

This module is a collection of advanced functions for functionality in Puppet that is otherwise only available in Ruby.
Checkout the list of features in the [description](#description)

1. [Description](#description)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Development - Guide for contributing to the module](#development)
4. [Reference - Function Reference](REFERENCE.md)

(In case you wonder "Tahu" is the Polynesian Tuamoto "God of Knowledge and Magic", son of Atea, the Creator).

## Description

This module provides features for:

* Stacktrace information
* Serialization and Deserialization
* Type reflection
* Data type parsing

#### Stacktrace

The functions `tahu::where` and `tahu::stacktrace` provides information how the logic ended up at a particular file and line.
This is useful for custom error messages in functions, or for debugging purposes - answering "how did it end up calling this function?".

### Type Reflection

Several functions allow getting more details about data types (an Integer data type for example has the attributes `to` and `from`)
and there are functions to get such values. There are also functions to get detailed information how functions can be called, how
objects and resource types can b created - what parameters they take and what their data types are.

This is useful in several cases - for example when reading information from a file that is then used in a call, or to create
resources and you want to provide better error messages than just getting a crash when attempting to make the call/create the resource
with the data that was given. Now you can check if the data is acceptable before making the call as this gives you an opportunity
to provide a better error message.

Other use cases could be to filter out parameters given in data when they are not compatible with a particular version of
a resource or object.

### Serialization and Deserialization

Puppet can read/write `RichData` values with a `Data` compatible encoding. This is used by Puppet when a Catalog is sent from
a master to an agent. Now you can do the same type of serializtion/deserialization. For example to read/write rich data from
YAML files.

### Data type parsing

The function `to_type` transforms a string into a data type. For example `tahu::to_type("Integer[1,10]")` would parse the string
and return the actual type.

## Usage

This modules contains advancd functions. Simply call them...

## Limitations

This module requires Puppet 6.1.0 for several of the functions.

## Development

Pull requests are accepted. Issues are tracked at github. This module was developed with PDK and documentation is generated with
Puppet Strings.

## Release Notes/Contributors/Etc. **Optional**

Written by Henrik Lindberg - Slack/IRC: helindbe.

* Nothing to see here yet - this is just release

