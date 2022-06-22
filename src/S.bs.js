'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Js_dict = require("rescript/lib/js/js_dict.js");
var Js_types = require("rescript/lib/js/js_types.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

function callWithArguments(fn) {
  return (function(){return fn(arguments)});
}

class RescriptStructError extends Error {
    constructor(message) {
      super(message);
      this.name = "RescriptStructError";
    }
  }
;

var raise = (function(message){
    throw new RescriptStructError(message);
  });

function toParseError(self) {
  return {
          operation: /* Parsing */1,
          code: self.code,
          path: self.path
        };
}

function toSerializeError(self) {
  return {
          operation: /* Serializing */0,
          code: self.code,
          path: self.path
        };
}

function fromPublic($$public) {
  return {
          code: $$public.code,
          path: $$public.path
        };
}

function prependLocation(error, $$location) {
  return {
          code: error.code,
          path: [$$location].concat(error.path)
        };
}

function stringify(any) {
  if (any === undefined) {
    return "undefined";
  }
  var string = JSON.stringify(Caml_option.valFromOption(any));
  if (string !== undefined) {
    return string;
  } else {
    return "???";
  }
}

function make(expected, received) {
  var code_0 = stringify(expected);
  var code_1 = stringify(received);
  var code = {
    TAG: /* UnexpectedValue */2,
    expected: code_0,
    received: code_1
  };
  return {
          code: code,
          path: []
        };
}

function raise$1($$location) {
  return raise("For a " + $$location + " either a parser, or a serializer is required");
}

function formatPath(path) {
  if (path.length === 0) {
    return "root";
  } else {
    return path.map(function (pathItem) {
                  return "[" + pathItem + "]";
                }).join("");
  }
}

function prependLocation$1(error, $$location) {
  return {
          operation: error.operation,
          code: error.code,
          path: [$$location].concat(error.path)
        };
}

function make$1(reason) {
  return {
          operation: /* Parsing */1,
          code: {
            TAG: /* OperationFailed */0,
            _0: reason
          },
          path: []
        };
}

function toString(error) {
  var match = error.operation;
  var operation = match ? "parsing" : "serializing";
  var pathText = formatPath(error.path);
  var reason = error.code;
  var reason$1;
  var exit = 0;
  if (typeof reason === "number") {
    reason$1 = reason === /* MissingParser */0 ? "Struct parser is missing" : "Struct serializer is missing";
  } else {
    switch (reason.TAG | 0) {
      case /* OperationFailed */0 :
          reason$1 = reason._0;
          break;
      case /* UnexpectedType */1 :
      case /* UnexpectedValue */2 :
          exit = 1;
          break;
      case /* TupleSize */3 :
          reason$1 = "Expected Tuple with " + reason.expected.toString() + " items, received " + reason.received.toString();
          break;
      case /* ExcessField */4 :
          reason$1 = "Encountered disallowed excess key \"" + reason._0 + "\" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely";
          break;
      
    }
  }
  if (exit === 1) {
    reason$1 = "Expected " + reason.expected + ", received " + reason.received;
  }
  return "[ReScript Struct]" + " Failed " + operation + " at " + pathText + ". Reason: " + reason$1;
}

function classify(struct) {
  return struct.tagged_t;
}

function toString$1(tagged_t) {
  if (typeof tagged_t === "number") {
    switch (tagged_t) {
      case /* Never */0 :
          return "Never";
      case /* Unknown */1 :
          return "Unknown";
      case /* String */2 :
          return "String";
      case /* Int */3 :
          return "Int";
      case /* Float */4 :
          return "Float";
      case /* Bool */5 :
          return "Bool";
      
    }
  } else {
    switch (tagged_t.TAG | 0) {
      case /* Literal */0 :
          var literal = tagged_t._0;
          if (typeof literal === "number") {
            switch (literal) {
              case /* EmptyNull */0 :
                  return "EmptyNull Literal (null)";
              case /* EmptyOption */1 :
                  return "EmptyOption Literal (undefined)";
              case /* NaN */2 :
                  return "NaN Literal (NaN)";
              
            }
          } else {
            switch (literal.TAG | 0) {
              case /* String */0 :
                  return "String Literal (\"" + literal._0 + "\")";
              case /* Int */1 :
                  return "Int Literal (" + literal._0 + ")";
              case /* Float */2 :
                  return "Float Literal (" + literal._0 + ")";
              case /* Bool */3 :
                  return "Bool Literal (" + literal._0 + ")";
              
            }
          }
      case /* Option */1 :
          return "Option";
      case /* Null */2 :
          return "Null";
      case /* Array */3 :
          return "Array";
      case /* Record */4 :
          return "Record";
      case /* Tuple */5 :
          return "Tuple";
      case /* Union */6 :
          return "Union";
      case /* Dict */7 :
          return "Dict";
      case /* Deprecated */8 :
          return "Deprecated";
      case /* Default */9 :
          return "Default";
      
    }
  }
}

function makeUnexpectedTypeError(input, struct) {
  var typesTagged = Js_types.classify(input);
  var structTagged = struct.tagged_t;
  var received;
  if (typeof typesTagged === "number") {
    switch (typesTagged) {
      case /* JSFalse */0 :
      case /* JSTrue */1 :
          received = "Bool";
          break;
      case /* JSNull */2 :
          received = "Null";
          break;
      case /* JSUndefined */3 :
          received = "Option";
          break;
      
    }
  } else {
    switch (typesTagged.TAG | 0) {
      case /* JSNumber */0 :
          received = Number.isNaN(typesTagged._0) ? "NaN Literal (NaN)" : "Float";
          break;
      case /* JSString */1 :
          received = "String";
          break;
      case /* JSFunction */2 :
          received = "Function";
          break;
      case /* JSObject */3 :
          received = "Object";
          break;
      case /* JSSymbol */4 :
          received = "Symbol";
          break;
      
    }
  }
  var expected = toString$1(structTagged);
  return {
          code: {
            TAG: /* UnexpectedType */1,
            expected: expected,
            received: received
          },
          path: []
        };
}

function applyOperations(operations, initial, mode, struct) {
  var idxRef = 0;
  var valueRef = initial;
  var maybeErrorRef;
  var shouldSkipRefinements = mode ? true : false;
  while(idxRef < operations.length && maybeErrorRef === undefined) {
    var operation = operations[idxRef];
    if (operation.TAG === /* Transform */0) {
      var newValue = operation._0(valueRef, struct, mode);
      if (newValue.TAG === /* Ok */0) {
        valueRef = newValue._0;
        idxRef = idxRef + 1 | 0;
      } else {
        maybeErrorRef = newValue._0;
      }
    } else if (shouldSkipRefinements) {
      idxRef = idxRef + 1 | 0;
    } else {
      var someError = operation._0(valueRef, struct);
      if (someError !== undefined) {
        maybeErrorRef = someError;
      } else {
        idxRef = idxRef + 1 | 0;
      }
    }
  };
  var error = maybeErrorRef;
  if (error !== undefined) {
    return {
            TAG: /* Error */1,
            _0: error
          };
  } else {
    return {
            TAG: /* Ok */0,
            _0: valueRef
          };
  }
}

function parseInner(struct, any, mode) {
  var parsers = struct.maybeParsers;
  if (parsers !== undefined) {
    return applyOperations(parsers, any, mode, struct);
  } else {
    return {
            TAG: /* Error */1,
            _0: {
              code: /* MissingParser */0,
              path: []
            }
          };
  }
}

function parseWith(any, modeOpt, struct) {
  var mode = modeOpt !== undefined ? modeOpt : /* Safe */0;
  var result = parseInner(struct, any, mode);
  if (result.TAG === /* Ok */0) {
    return result;
  } else {
    return {
            TAG: /* Error */1,
            _0: toParseError(result._0)
          };
  }
}

function serializeInner(struct, value, mode) {
  var serializers = struct.maybeSerializers;
  if (serializers !== undefined) {
    return applyOperations(serializers, value, mode, struct);
  } else {
    return {
            TAG: /* Error */1,
            _0: {
              code: /* MissingSerializer */1,
              path: []
            }
          };
  }
}

function serializeWith(value, modeOpt, struct) {
  var mode = modeOpt !== undefined ? modeOpt : /* Safe */0;
  var result = serializeInner(struct, value, mode);
  if (result.TAG === /* Ok */0) {
    return result;
  } else {
    return {
            TAG: /* Error */1,
            _0: toSerializeError(result._0)
          };
  }
}

var empty = [];

var literalValueRefinement = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      var expectedValue = struct.tagged_t._0._0;
      if (expectedValue === input) {
        return ;
      } else {
        return make(expectedValue, input);
      }
    })
};

var transformToLiteralValue = {
  TAG: /* Transform */0,
  _0: (function (param, struct, param$1) {
      var literalValue = struct.tagged_t._0._0;
      return {
              TAG: /* Ok */0,
              _0: literalValue
            };
    })
};

var parserRefinement = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (input === null) {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

var serializerTransform = {
  TAG: /* Transform */0,
  _0: (function (param, param$1, param$2) {
      return {
              TAG: /* Ok */0,
              _0: null
            };
    })
};

var parserRefinement$1 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (input === undefined) {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

var serializerTransform$1 = {
  TAG: /* Transform */0,
  _0: (function (param, param$1, param$2) {
      return {
              TAG: /* Ok */0,
              _0: undefined
            };
    })
};

var parserRefinement$2 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (Number.isNaN(input)) {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

var serializerTransform$2 = {
  TAG: /* Transform */0,
  _0: (function (param, param$1, param$2) {
      return {
              TAG: /* Ok */0,
              _0: NaN
            };
    })
};

var parserRefinement$3 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "boolean") {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

var parserRefinement$4 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "string") {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

var parserRefinement$5 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "number") {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

var parserRefinement$6 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
        return ;
      } else {
        return makeUnexpectedTypeError(input, struct);
      }
    })
};

function factory(innerLiteral, variant) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  var parserTransform = {
    TAG: /* Transform */0,
    _0: (function (param, param$1, param$2) {
        return {
                TAG: /* Ok */0,
                _0: variant
              };
      })
  };
  var serializerRefinement = {
    TAG: /* Refinement */1,
    _0: (function (input, param) {
        if (input === variant) {
          return ;
        } else {
          return make(variant, input);
        }
      })
  };
  if (typeof innerLiteral === "number") {
    switch (innerLiteral) {
      case /* EmptyNull */0 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    serializerTransform
                  ],
                  maybeMetadata: undefined
                };
      case /* EmptyOption */1 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement$1,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    serializerTransform$1
                  ],
                  maybeMetadata: undefined
                };
      case /* NaN */2 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement$2,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    serializerTransform$2
                  ],
                  maybeMetadata: undefined
                };
      
    }
  } else {
    switch (innerLiteral.TAG | 0) {
      case /* String */0 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement$4,
                    literalValueRefinement,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    transformToLiteralValue
                  ],
                  maybeMetadata: undefined
                };
      case /* Int */1 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement$6,
                    literalValueRefinement,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    transformToLiteralValue
                  ],
                  maybeMetadata: undefined
                };
      case /* Float */2 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement$5,
                    literalValueRefinement,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    transformToLiteralValue
                  ],
                  maybeMetadata: undefined
                };
      case /* Bool */3 :
          return {
                  tagged_t: tagged_t,
                  maybeParsers: [
                    parserRefinement$3,
                    literalValueRefinement,
                    parserTransform
                  ],
                  maybeSerializers: [
                    serializerRefinement,
                    transformToLiteralValue
                  ],
                  maybeMetadata: undefined
                };
      
    }
  }
}

function factory$1(innerLiteral) {
  if (typeof innerLiteral === "number") {
    return factory(innerLiteral, undefined);
  } else {
    return factory(innerLiteral, innerLiteral._0);
  }
}

var getMaybeExcessKey = (function(object, innerStructsDict) {
    for (var key in object) {
      if (!(key in innerStructsDict)) {
        return key
      }
    }
    return undefined
  });

var parsers = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var maybeRefinementError = mode || Object.prototype.toString.call(input) === "[object Object]" ? undefined : makeUnexpectedTypeError(input, struct);
        if (maybeRefinementError !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: maybeRefinementError
                };
        }
        var match = struct.tagged_t;
        var fieldNames = match.fieldNames;
        var fields = match.fields;
        var newArray = [];
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < fieldNames.length && maybeErrorRef === undefined) {
          var idx = idxRef;
          var fieldName = fieldNames[idx];
          var fieldStruct = fields[fieldName];
          var value = parseInner(fieldStruct, input[fieldName], mode);
          if (value.TAG === /* Ok */0) {
            newArray.push(value._0);
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, fieldName);
          }
        };
        if (match.unknownKeys === /* Strict */0 && mode === /* Safe */0) {
          var excessKey = getMaybeExcessKey(input, fields);
          if (excessKey !== undefined) {
            maybeErrorRef = {
              code: {
                TAG: /* ExcessField */4,
                _0: excessKey
              },
              path: []
            };
          }
          
        }
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newArray.length <= 1 ? newArray[0] : newArray
                };
        }
      })
  }];

var serializers = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var match = struct.tagged_t;
        var fieldNames = match.fieldNames;
        var fields = match.fields;
        var unknown = {};
        var fieldValues = fieldNames.length <= 1 ? [input] : input;
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < fieldNames.length && maybeErrorRef === undefined) {
          var idx = idxRef;
          var fieldName = fieldNames[idx];
          var fieldStruct = fields[fieldName];
          var fieldValue = fieldValues[idx];
          var unknownFieldValue = serializeInner(fieldStruct, fieldValue, mode);
          if (unknownFieldValue.TAG === /* Ok */0) {
            unknown[fieldName] = unknownFieldValue._0;
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(unknownFieldValue._0, fieldName);
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: unknown
                };
        }
      })
  }];

function innerFactory(fieldsArray) {
  var fields = Js_dict.fromArray(fieldsArray);
  return {
          tagged_t: {
            TAG: /* Record */4,
            fields: fields,
            fieldNames: Object.keys(fields),
            unknownKeys: /* Strict */0
          },
          maybeParsers: parsers,
          maybeSerializers: serializers,
          maybeMetadata: undefined
        };
}

var factory$2 = callWithArguments(innerFactory);

function strip(struct) {
  var tagged_t = struct.tagged_t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return raise("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return {
            tagged_t: {
              TAG: /* Record */4,
              fields: tagged_t.fields,
              fieldNames: tagged_t.fieldNames,
              unknownKeys: /* Strip */1
            },
            maybeParsers: struct.maybeParsers,
            maybeSerializers: struct.maybeSerializers,
            maybeMetadata: struct.maybeMetadata
          };
  }
}

function strict(struct) {
  var tagged_t = struct.tagged_t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return raise("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return {
            tagged_t: {
              TAG: /* Record */4,
              fields: tagged_t.fields,
              fieldNames: tagged_t.fieldNames,
              unknownKeys: /* Strict */0
            },
            maybeParsers: struct.maybeParsers,
            maybeSerializers: struct.maybeSerializers,
            maybeMetadata: struct.maybeMetadata
          };
  }
}

var parsers$1 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        return makeUnexpectedTypeError(input, struct);
      })
  }];

function factory$3(param) {
  return {
          tagged_t: /* Never */0,
          maybeParsers: parsers$1,
          maybeSerializers: empty,
          maybeMetadata: undefined
        };
}

function factory$4(param) {
  return {
          tagged_t: /* Unknown */1,
          maybeParsers: empty,
          maybeSerializers: empty,
          maybeMetadata: undefined
        };
}

var parsers$2 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "string") {
          return ;
        } else {
          return makeUnexpectedTypeError(input, struct);
        }
      })
  }];

function factory$5(param) {
  return {
          tagged_t: /* String */2,
          maybeParsers: parsers$2,
          maybeSerializers: empty,
          maybeMetadata: undefined
        };
}

var parsers$3 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "boolean") {
          return ;
        } else {
          return makeUnexpectedTypeError(input, struct);
        }
      })
  }];

function factory$6(param) {
  return {
          tagged_t: /* Bool */5,
          maybeParsers: parsers$3,
          maybeSerializers: empty,
          maybeMetadata: undefined
        };
}

var parsers$4 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
          return ;
        } else {
          return makeUnexpectedTypeError(input, struct);
        }
      })
  }];

function factory$7(param) {
  return {
          tagged_t: /* Int */3,
          maybeParsers: parsers$4,
          maybeSerializers: empty,
          maybeMetadata: undefined
        };
}

var parsers$5 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "number" && !Number.isNaN(input)) {
          return ;
        } else {
          return makeUnexpectedTypeError(input, struct);
        }
      })
  }];

function factory$8(param) {
  return {
          tagged_t: /* Float */4,
          maybeParsers: parsers$5,
          maybeSerializers: empty,
          maybeMetadata: undefined
        };
}

var parsers$6 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        if (input === null) {
          return {
                  TAG: /* Ok */0,
                  _0: undefined
                };
        }
        var innerStruct = struct.tagged_t._0;
        var result = parseInner(innerStruct, input, mode);
        if (result.TAG === /* Ok */0) {
          return {
                  TAG: /* Ok */0,
                  _0: Caml_option.some(result._0)
                };
        } else {
          return result;
        }
      })
  }];

var serializers$1 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        if (input === undefined) {
          return {
                  TAG: /* Ok */0,
                  _0: null
                };
        }
        var innerStruct = struct.tagged_t._0;
        return serializeInner(innerStruct, Caml_option.valFromOption(input), mode);
      })
  }];

function factory$9(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Null */2,
            _0: innerStruct
          },
          maybeParsers: parsers$6,
          maybeSerializers: serializers$1,
          maybeMetadata: undefined
        };
}

var parsers$7 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        if (input === undefined) {
          return {
                  TAG: /* Ok */0,
                  _0: undefined
                };
        }
        var innerStruct = struct.tagged_t._0;
        var result = parseInner(innerStruct, Caml_option.valFromOption(input), mode);
        if (result.TAG === /* Ok */0) {
          return {
                  TAG: /* Ok */0,
                  _0: Caml_option.some(result._0)
                };
        } else {
          return result;
        }
      })
  }];

var serializers$2 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        if (input === undefined) {
          return {
                  TAG: /* Ok */0,
                  _0: undefined
                };
        }
        var innerStruct = struct.tagged_t._0;
        return serializeInner(innerStruct, Caml_option.valFromOption(input), mode);
      })
  }];

function factory$10(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Option */1,
            _0: innerStruct
          },
          maybeParsers: parsers$7,
          maybeSerializers: serializers$2,
          maybeMetadata: undefined
        };
}

var parsers$8 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        if (input === undefined) {
          return {
                  TAG: /* Ok */0,
                  _0: undefined
                };
        }
        var match = struct.tagged_t;
        var result = parseInner(match.struct, Caml_option.valFromOption(input), mode);
        if (result.TAG === /* Ok */0) {
          return {
                  TAG: /* Ok */0,
                  _0: Caml_option.some(result._0)
                };
        } else {
          return result;
        }
      })
  }];

var serializers$3 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        if (input === undefined) {
          return {
                  TAG: /* Ok */0,
                  _0: undefined
                };
        }
        var match = struct.tagged_t;
        return serializeInner(match.struct, Caml_option.valFromOption(input), mode);
      })
  }];

function factory$11(maybeMessage, innerStruct) {
  return {
          tagged_t: {
            TAG: /* Deprecated */8,
            struct: innerStruct,
            maybeMessage: maybeMessage
          },
          maybeParsers: parsers$8,
          maybeSerializers: serializers$3,
          maybeMetadata: undefined
        };
}

var parsers$9 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var maybeRefinementError = mode || Array.isArray(input) ? undefined : makeUnexpectedTypeError(input, struct);
        if (maybeRefinementError !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: maybeRefinementError
                };
        }
        var innerStruct = struct.tagged_t._0;
        var newArray = [];
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < input.length && maybeErrorRef === undefined) {
          var idx = idxRef;
          var innerValue = input[idx];
          var value = parseInner(innerStruct, innerValue, mode);
          if (value.TAG === /* Ok */0) {
            newArray.push(value._0);
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, idx.toString());
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newArray
                };
        }
      })
  }];

var serializers$4 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var innerStruct = struct.tagged_t._0;
        var newArray = [];
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < input.length && maybeErrorRef === undefined) {
          var idx = idxRef;
          var innerValue = input[idx];
          var value = serializeInner(innerStruct, innerValue, mode);
          if (value.TAG === /* Ok */0) {
            newArray.push(value._0);
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, idx.toString());
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newArray
                };
        }
      })
  }];

function factory$12(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Array */3,
            _0: innerStruct
          },
          maybeParsers: parsers$9,
          maybeSerializers: serializers$4,
          maybeMetadata: undefined
        };
}

var parsers$10 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var maybeRefinementError = mode || Object.prototype.toString.call(input) === "[object Object]" ? undefined : makeUnexpectedTypeError(input, struct);
        if (maybeRefinementError !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: maybeRefinementError
                };
        }
        var innerStruct = struct.tagged_t._0;
        var newDict = {};
        var keys = Object.keys(input);
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < keys.length && maybeErrorRef === undefined) {
          var idx = idxRef;
          var key = keys[idx];
          var innerValue = input[key];
          var value = parseInner(innerStruct, innerValue, mode);
          if (value.TAG === /* Ok */0) {
            newDict[key] = value._0;
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, key);
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newDict
                };
        }
      })
  }];

var serializers$5 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var innerStruct = struct.tagged_t._0;
        var newDict = {};
        var keys = Object.keys(input);
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < keys.length && maybeErrorRef === undefined) {
          var idx = idxRef;
          var key = keys[idx];
          var innerValue = input[key];
          var value = serializeInner(innerStruct, innerValue, mode);
          if (value.TAG === /* Ok */0) {
            newDict[key] = value._0;
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, key);
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newDict
                };
        }
      })
  }];

function factory$13(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Dict */7,
            _0: innerStruct
          },
          maybeParsers: parsers$10,
          maybeSerializers: serializers$5,
          maybeMetadata: undefined
        };
}

var parsers$11 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var match = struct.tagged_t;
        var value = match.value;
        var fn = function (maybeOutput) {
          if (maybeOutput !== undefined) {
            return Caml_option.valFromOption(maybeOutput);
          } else {
            return value;
          }
        };
        var result = parseInner(match.struct, input, mode);
        if (result.TAG === /* Ok */0) {
          return {
                  TAG: /* Ok */0,
                  _0: fn(result._0)
                };
        } else {
          return result;
        }
      })
  }];

var serializers$6 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var match = struct.tagged_t;
        return serializeInner(match.struct, Caml_option.some(input), mode);
      })
  }];

function factory$14(innerStruct, defaultValue) {
  return {
          tagged_t: {
            TAG: /* Default */9,
            struct: innerStruct,
            value: defaultValue
          },
          maybeParsers: parsers$11,
          maybeSerializers: serializers$6,
          maybeMetadata: undefined
        };
}

var parsers$12 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var innerStructs = struct.tagged_t._0;
        var numberOfStructs = innerStructs.length;
        var maybeRefinementError;
        if (mode) {
          maybeRefinementError = undefined;
        } else if (Array.isArray(input)) {
          var numberOfInputItems = input.length;
          maybeRefinementError = numberOfStructs === numberOfInputItems ? undefined : ({
                code: {
                  TAG: /* TupleSize */3,
                  expected: numberOfStructs,
                  received: numberOfInputItems
                },
                path: []
              });
        } else {
          maybeRefinementError = makeUnexpectedTypeError(input, struct);
        }
        if (maybeRefinementError !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: maybeRefinementError
                };
        }
        var newArray = [];
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < numberOfStructs && maybeErrorRef === undefined) {
          var idx = idxRef;
          var innerValue = input[idx];
          var innerStruct = innerStructs[idx];
          var value = parseInner(innerStruct, innerValue, mode);
          if (value.TAG === /* Ok */0) {
            newArray.push(value._0);
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, idx.toString());
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: numberOfStructs !== 0 ? (
                      numberOfStructs !== 1 ? newArray : newArray[0]
                    ) : undefined
                };
        }
      })
  }];

var serializers$7 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var innerStructs = struct.tagged_t._0;
        var numberOfStructs = innerStructs.length;
        var inputArray = numberOfStructs === 1 ? [input] : input;
        var newArray = [];
        var idxRef = 0;
        var maybeErrorRef;
        while(idxRef < numberOfStructs && maybeErrorRef === undefined) {
          var idx = idxRef;
          var innerValue = inputArray[idx];
          var innerStruct = innerStructs[idx];
          var value = serializeInner(innerStruct, innerValue, mode);
          if (value.TAG === /* Ok */0) {
            newArray.push(value._0);
            idxRef = idxRef + 1 | 0;
          } else {
            maybeErrorRef = prependLocation(value._0, idx.toString());
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: error
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newArray
                };
        }
      })
  }];

function innerFactory$1(structs) {
  return {
          tagged_t: {
            TAG: /* Tuple */5,
            _0: structs
          },
          maybeParsers: parsers$12,
          maybeSerializers: serializers$7,
          maybeMetadata: undefined
        };
}

var factory$15 = callWithArguments(innerFactory$1);

var parsers$13 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, param) {
        var innerStructs = struct.tagged_t._0;
        var idxRef = 0;
        var maybeLastErrorRef;
        var maybeOkRef;
        while(idxRef < innerStructs.length && maybeOkRef === undefined) {
          var idx = idxRef;
          var innerStruct = innerStructs[idx];
          var ok = parseInner(innerStruct, input, /* Safe */0);
          if (ok.TAG === /* Ok */0) {
            maybeOkRef = ok;
          } else {
            maybeLastErrorRef = ok;
            idxRef = idxRef + 1 | 0;
          }
        };
        var ok$1 = maybeOkRef;
        if (ok$1 !== undefined) {
          return ok$1;
        }
        var error = maybeLastErrorRef;
        if (error !== undefined) {
          return error;
        } else {
          return undefined;
        }
      })
  }];

var serializers$8 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, param) {
        var innerStructs = struct.tagged_t._0;
        var idxRef = 0;
        var maybeLastErrorRef;
        var maybeOkRef;
        while(idxRef < innerStructs.length && maybeOkRef === undefined) {
          var idx = idxRef;
          var innerStruct = innerStructs[idx];
          var ok = serializeInner(innerStruct, input, /* Safe */0);
          if (ok.TAG === /* Ok */0) {
            maybeOkRef = ok;
          } else {
            maybeLastErrorRef = ok;
            idxRef = idxRef + 1 | 0;
          }
        };
        var ok$1 = maybeOkRef;
        if (ok$1 !== undefined) {
          return ok$1;
        }
        var error = maybeLastErrorRef;
        if (error !== undefined) {
          return error;
        } else {
          return undefined;
        }
      })
  }];

function factory$16(structs) {
  if (structs.length < 2) {
    raise("A Union struct factory require at least two structs");
  }
  return {
          tagged_t: {
            TAG: /* Union */6,
            _0: structs
          },
          maybeParsers: parsers$13,
          maybeSerializers: serializers$8,
          maybeMetadata: undefined
        };
}

function json(struct) {
  return {
          tagged_t: /* String */2,
          maybeParsers: parsers$2.concat([{
                  TAG: /* Transform */0,
                  _0: (function (input, param, mode) {
                      var result;
                      var exit = 0;
                      var json;
                      try {
                        json = JSON.parse(input);
                        exit = 1;
                      }
                      catch (raw_obj){
                        var obj = Caml_js_exceptions.internalToOCamlException(raw_obj);
                        if (obj.RE_EXN_ID === Js_exn.$$Error) {
                          var maybeMessage = obj._1.message;
                          var code = {
                            TAG: /* OperationFailed */0,
                            _0: Belt_Option.getWithDefault(maybeMessage, "Syntax error")
                          };
                          result = {
                            TAG: /* Error */1,
                            _0: {
                              code: code,
                              path: []
                            }
                          };
                        } else {
                          throw obj;
                        }
                      }
                      if (exit === 1) {
                        result = {
                          TAG: /* Ok */0,
                          _0: json
                        };
                      }
                      if (result.TAG === /* Ok */0) {
                        return parseInner(struct, result._0, mode);
                      } else {
                        return result;
                      }
                    })
                }]),
          maybeSerializers: [{
                TAG: /* Transform */0,
                _0: (function (input, param, mode) {
                    var result = serializeInner(struct, input, mode);
                    if (result.TAG === /* Ok */0) {
                      return {
                              TAG: /* Ok */0,
                              _0: JSON.stringify(result._0)
                            };
                    } else {
                      return result;
                    }
                  })
              }].concat(empty),
          maybeMetadata: undefined
        };
}

function refine(struct, maybeParserRefine, maybeSerializerRefine, param) {
  if (maybeParserRefine === undefined && maybeSerializerRefine === undefined) {
    raise$1("struct factory Refine");
  }
  var match = struct.maybeParsers;
  var tmp;
  if (match !== undefined && maybeParserRefine !== undefined) {
    var parserRefine = Caml_option.valFromOption(maybeParserRefine);
    tmp = match.concat([{
            TAG: /* Refinement */1,
            _0: (function (input, param) {
                var option = parserRefine(input);
                if (option !== undefined) {
                  return {
                          code: {
                            TAG: /* OperationFailed */0,
                            _0: Caml_option.valFromOption(option)
                          },
                          path: []
                        };
                }
                
              })
          }]);
  } else {
    tmp = undefined;
  }
  var match$1 = struct.maybeSerializers;
  var tmp$1;
  if (match$1 !== undefined && maybeSerializerRefine !== undefined) {
    var serializerRefine = Caml_option.valFromOption(maybeSerializerRefine);
    tmp$1 = [{
          TAG: /* Refinement */1,
          _0: (function (input, param) {
              var option = serializerRefine(input);
              if (option !== undefined) {
                return {
                        code: {
                          TAG: /* OperationFailed */0,
                          _0: Caml_option.valFromOption(option)
                        },
                        path: []
                      };
              }
              
            })
        }].concat(match$1);
  } else {
    tmp$1 = undefined;
  }
  return {
          tagged_t: struct.tagged_t,
          maybeParsers: tmp,
          maybeSerializers: tmp$1,
          maybeMetadata: struct.maybeMetadata
        };
}

function transform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    raise$1("struct factory Transform");
  }
  var match = struct.maybeParsers;
  var tmp;
  if (match !== undefined && maybeTransformationParser !== undefined) {
    var transformationParser = Caml_option.valFromOption(maybeTransformationParser);
    tmp = match.concat([{
            TAG: /* Transform */0,
            _0: (function (input, param, param$1) {
                var result = transformationParser(input);
                if (result.TAG === /* Ok */0) {
                  return result;
                } else {
                  return {
                          TAG: /* Error */1,
                          _0: {
                            code: {
                              TAG: /* OperationFailed */0,
                              _0: result._0
                            },
                            path: []
                          }
                        };
                }
              })
          }]);
  } else {
    tmp = undefined;
  }
  var match$1 = struct.maybeSerializers;
  var tmp$1;
  if (match$1 !== undefined && maybeTransformationSerializer !== undefined) {
    var transformationSerializer = Caml_option.valFromOption(maybeTransformationSerializer);
    tmp$1 = [{
          TAG: /* Transform */0,
          _0: (function (input, param, param$1) {
              var result = transformationSerializer(input);
              if (result.TAG === /* Ok */0) {
                return result;
              } else {
                return {
                        TAG: /* Error */1,
                        _0: {
                          code: {
                            TAG: /* OperationFailed */0,
                            _0: result._0
                          },
                          path: []
                        }
                      };
              }
            })
        }].concat(match$1);
  } else {
    tmp$1 = undefined;
  }
  return {
          tagged_t: struct.tagged_t,
          maybeParsers: tmp,
          maybeSerializers: tmp$1,
          maybeMetadata: struct.maybeMetadata
        };
}

function superTransform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    raise$1("struct factory Transform");
  }
  var match = struct.maybeParsers;
  var match$1 = struct.maybeSerializers;
  return {
          tagged_t: struct.tagged_t,
          maybeParsers: match !== undefined && maybeTransformationParser !== undefined ? match.concat([{
                    TAG: /* Transform */0,
                    _0: (function (input, struct, mode) {
                        var result = maybeTransformationParser(input, struct, mode);
                        if (result.TAG === /* Ok */0) {
                          return result;
                        } else {
                          return {
                                  TAG: /* Error */1,
                                  _0: fromPublic(result._0)
                                };
                        }
                      })
                  }]) : undefined,
          maybeSerializers: match$1 !== undefined && maybeTransformationSerializer !== undefined ? [{
                  TAG: /* Transform */0,
                  _0: (function (input, struct, mode) {
                      var result = maybeTransformationSerializer(input, struct, mode);
                      if (result.TAG === /* Ok */0) {
                        return result;
                      } else {
                        return {
                                TAG: /* Error */1,
                                _0: fromPublic(result._0)
                              };
                      }
                    })
                }].concat(match$1) : undefined,
          maybeMetadata: struct.maybeMetadata
        };
}

function custom(maybeCustomParser, maybeCustomSerializer, param) {
  if (maybeCustomParser === undefined && maybeCustomSerializer === undefined) {
    raise$1("Custom struct factory");
  }
  var fn = function (customParser) {
    return [{
              TAG: /* Transform */0,
              _0: (function (input, param, mode) {
                  var result = customParser(input, mode);
                  if (result.TAG === /* Ok */0) {
                    return result;
                  } else {
                    return {
                            TAG: /* Error */1,
                            _0: fromPublic(result._0)
                          };
                  }
                })
            }];
  };
  var fn$1 = function (customSerializer) {
    return [{
              TAG: /* Transform */0,
              _0: (function (input, param, mode) {
                  var result = customSerializer(input, mode);
                  if (result.TAG === /* Ok */0) {
                    return result;
                  } else {
                    return {
                            TAG: /* Error */1,
                            _0: fromPublic(result._0)
                          };
                  }
                })
            }];
  };
  return {
          tagged_t: /* Unknown */1,
          maybeParsers: maybeCustomParser !== undefined ? Caml_option.some(fn(Caml_option.valFromOption(maybeCustomParser))) : undefined,
          maybeSerializers: maybeCustomSerializer !== undefined ? Caml_option.some(fn$1(Caml_option.valFromOption(maybeCustomSerializer))) : undefined,
          maybeMetadata: undefined
        };
}

function getExn(result) {
  if (result.TAG === /* Ok */0) {
    return result._0;
  } else {
    return raise(toString(result._0));
  }
}

function mapErrorToString(result) {
  if (result.TAG === /* Ok */0) {
    return result;
  } else {
    return {
            TAG: /* Error */1,
            _0: toString(result._0)
          };
  }
}

var Result = {
  getExn: getExn,
  mapErrorToString: mapErrorToString
};

var $$Error = {
  prependLocation: prependLocation$1,
  make: make$1,
  toString: toString
};

var never = factory$3;

var unknown = factory$4;

var string = factory$5;

var bool = factory$6;

var $$int = factory$7;

var $$float = factory$8;

var literal = factory$1;

var literalVariant = factory;

var array = factory$12;

var dict = factory$13;

var option = factory$10;

var $$null = factory$9;

var deprecated = factory$11;

var $$default = factory$14;

var union = factory$16;

var Record = {
  factory: factory$2,
  strip: strip,
  strict: strict
};

var record0 = factory$2;

var record1 = factory$2;

var record2 = factory$2;

var record3 = factory$2;

var record4 = factory$2;

var record5 = factory$2;

var record6 = factory$2;

var record7 = factory$2;

var record8 = factory$2;

var record9 = factory$2;

var record10 = factory$2;

var Tuple = {
  factory: factory$15
};

var tuple0 = factory$15;

var tuple1 = factory$15;

var tuple2 = factory$15;

var tuple3 = factory$15;

var tuple4 = factory$15;

var tuple5 = factory$15;

var tuple6 = factory$15;

var tuple7 = factory$15;

var tuple8 = factory$15;

var tuple9 = factory$15;

var tuple10 = factory$15;

function MakeMetadata(funarg) {
  var get = function (struct) {
    var option = struct.maybeMetadata;
    if (option !== undefined) {
      return Caml_option.some(Js_dict.get(Caml_option.valFromOption(option), funarg.namespace));
    }
    
  };
  var dictUnsafeSet = function (dict, key, value) {
    return ({
      ...dict,
      [key]: value,
    });
  };
  var set = function (struct, content) {
    var currentContent = struct.maybeMetadata;
    var existingContent = currentContent !== undefined ? Caml_option.valFromOption(currentContent) : ({});
    return {
            tagged_t: struct.tagged_t,
            maybeParsers: struct.maybeParsers,
            maybeSerializers: struct.maybeSerializers,
            maybeMetadata: Caml_option.some(dictUnsafeSet(existingContent, funarg.namespace, content))
          };
  };
  return {
          get: get,
          set: set
        };
}

exports.$$Error = $$Error;
exports.never = never;
exports.unknown = unknown;
exports.string = string;
exports.bool = bool;
exports.$$int = $$int;
exports.$$float = $$float;
exports.literal = literal;
exports.literalVariant = literalVariant;
exports.array = array;
exports.dict = dict;
exports.option = option;
exports.$$null = $$null;
exports.deprecated = deprecated;
exports.$$default = $$default;
exports.default = $$default;
exports.__esModule = true;
exports.json = json;
exports.union = union;
exports.transform = transform;
exports.superTransform = superTransform;
exports.custom = custom;
exports.refine = refine;
exports.parseWith = parseWith;
exports.serializeWith = serializeWith;
exports.Record = Record;
exports.record0 = record0;
exports.record1 = record1;
exports.record2 = record2;
exports.record3 = record3;
exports.record4 = record4;
exports.record5 = record5;
exports.record6 = record6;
exports.record7 = record7;
exports.record8 = record8;
exports.record9 = record9;
exports.record10 = record10;
exports.Tuple = Tuple;
exports.tuple0 = tuple0;
exports.tuple1 = tuple1;
exports.tuple2 = tuple2;
exports.tuple3 = tuple3;
exports.tuple4 = tuple4;
exports.tuple5 = tuple5;
exports.tuple6 = tuple6;
exports.tuple7 = tuple7;
exports.tuple8 = tuple8;
exports.tuple9 = tuple9;
exports.tuple10 = tuple10;
exports.classify = classify;
exports.Result = Result;
exports.MakeMetadata = MakeMetadata;
/*  Not a pure module */
