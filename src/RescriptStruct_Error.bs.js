'use strict';


class RescriptStructError extends Error {
  constructor(message) {
    super(message);
    this.name = "RescriptStructError";
  }
}
;

var raiseRescriptStructError = (function(message){
  throw new RescriptStructError(message);
});

function raise($$location) {
  return raiseRescriptStructError("For a " + $$location + " either a constructor, or a destructor is required");
}

var MissingConstructorAndDestructor = {
  raise: raise
};

function raise$1(param) {
  return raiseRescriptStructError("Can't set up unknown keys strategy. The struct is not Record");
}

var UnknownKeysRequireRecord = {
  raise: raise$1
};

function make(reason) {
  return {
          operation: /* Parsing */1,
          reason: reason,
          path: []
        };
}

var ParsingFailed = {
  make: make
};

function make$1(reason) {
  return {
          operation: /* Serializing */0,
          reason: reason,
          path: []
        };
}

var SerializingFailed = {
  make: make$1
};

function make$2(param) {
  return {
          operation: /* Parsing */1,
          reason: "Struct constructor is missing",
          path: []
        };
}

var MissingConstructor = {
  make: make$2
};

function make$3(param) {
  return {
          operation: /* Serializing */0,
          reason: "Struct destructor is missing",
          path: []
        };
}

var MissingDestructor = {
  make: make$3
};

function make$4(expected, got, operation) {
  return {
          operation: operation,
          reason: "Expected " + expected + ", got " + got,
          path: []
        };
}

var UnexpectedType = {
  make: make$4
};

function make$5(expectedValue, gotValue, operation) {
  var reason = typeof expectedValue === "string" ? "Expected \"" + expectedValue + "\", got \"" + gotValue + "\"" : "Expected " + expectedValue + ", got " + gotValue;
  return {
          operation: operation,
          reason: reason,
          path: []
        };
}

var UnexpectedValue = {
  make: make$5
};

function make$6(fieldName) {
  return {
          operation: /* Parsing */1,
          reason: "Encountered disallowed excess key \"" + fieldName + "\" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely",
          path: []
        };
}

var ExcessField = {
  make: make$6
};

function formatPath(path) {
  if (path.length === 0) {
    return "root";
  } else {
    return path.map(function (pathItem) {
                  return "[" + pathItem + "]";
                }).join("");
  }
}

function prependField(error, field) {
  return {
          operation: error.operation,
          reason: error.reason,
          path: [field].concat(error.path)
        };
}

function prependIndex(error, index) {
  return prependField(error, index.toString());
}

function toString(error) {
  var match = error.operation;
  var operation = match ? "parsing" : "serializing";
  var pathText = formatPath(error.path);
  return "[ReScript Struct]" + " Failed " + operation + " at " + pathText + ". Reason: " + error.reason;
}

exports.MissingConstructorAndDestructor = MissingConstructorAndDestructor;
exports.UnknownKeysRequireRecord = UnknownKeysRequireRecord;
exports.MissingConstructor = MissingConstructor;
exports.MissingDestructor = MissingDestructor;
exports.ParsingFailed = ParsingFailed;
exports.SerializingFailed = SerializingFailed;
exports.UnexpectedType = UnexpectedType;
exports.UnexpectedValue = UnexpectedValue;
exports.ExcessField = ExcessField;
exports.prependField = prependField;
exports.prependIndex = prependIndex;
exports.toString = toString;
/*  Not a pure module */
