'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Js_dict = require("rescript/lib/js/js_dict.js");
var Js_types = require("rescript/lib/js/js_types.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

function factoryOf(self, data) {
  return (data instanceof self);
}

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

function toReason(nestedLevelOpt, error) {
  var nestedLevel = nestedLevelOpt !== undefined ? nestedLevelOpt : 0;
  var reason = error.code;
  if (typeof reason === "number") {
    if (reason === /* MissingParser */0) {
      return "Struct parser is missing";
    } else {
      return "Struct serializer is missing";
    }
  }
  switch (reason.TAG | 0) {
    case /* OperationFailed */0 :
        return reason._0;
    case /* UnexpectedType */1 :
    case /* UnexpectedValue */2 :
        break;
    case /* TupleSize */3 :
        return "Expected Tuple with " + reason.expected.toString() + " items, received " + reason.received.toString();
    case /* ExcessField */4 :
        return "Encountered disallowed excess key \"" + reason._0 + "\" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely";
    case /* InvalidUnion */5 :
        var lineBreak = "\n" + " ".repeat((nestedLevel << 1));
        var partial_arg = nestedLevel + 1;
        var array = reason._0.map(function (param) {
              return toReason(partial_arg, param);
            });
        var reasons = Array.from(new Set(array));
        return "Invalid union with following errors" + lineBreak + reasons.map(function (reason) {
                      return "- " + reason;
                    }).join(lineBreak);
    
  }
  return "Expected " + reason.expected + ", received " + reason.received;
}

function toString(error) {
  var match = error.operation;
  var operation = match ? "parsing" : "serializing";
  var reason = toReason(undefined, error);
  var pathText = formatPath(error.path);
  return "[ReScript Struct]" + " Failed " + operation + " at " + pathText + ". Reason: " + reason;
}

function classify(struct) {
  return struct.t;
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
      case /* Instance */10 :
          return "Instance (" + tagged_t._0.name + ")";
      
    }
  }
}

function makeUnexpectedTypeError(input, struct) {
  var typesTagged = Js_types.classify(input);
  var structTagged = struct.t;
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

function processInner(operation, input, mode, struct) {
  var effectsMap = operation ? struct.p : struct.s;
  var effects = mode ? effectsMap.u : effectsMap.s;
  var idxRef = 0;
  var valueRef = input;
  var maybeErrorRef;
  while(idxRef < effects.length && maybeErrorRef === undefined) {
    var effect = effects[idxRef];
    var newValue = effect(valueRef, struct, mode);
    if (typeof newValue === "number") {
      idxRef = idxRef + 1;
    } else if (newValue.TAG === /* Transformed */0) {
      valueRef = newValue._0;
      idxRef = idxRef + 1;
    } else {
      maybeErrorRef = newValue._0;
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

function parseWith(any, modeOpt, struct) {
  var mode = modeOpt !== undefined ? modeOpt : /* Safe */0;
  var result = processInner(/* Parsing */1, any, mode, struct);
  if (result.TAG === /* Ok */0) {
    return result;
  } else {
    return {
            TAG: /* Error */1,
            _0: toParseError(result._0)
          };
  }
}

function serializeWith(value, modeOpt, struct) {
  var mode = modeOpt !== undefined ? modeOpt : /* Safe */0;
  var result = processInner(/* Serializing */0, value, mode, struct);
  if (result.TAG === /* Ok */0) {
    return result;
  } else {
    return {
            TAG: /* Error */1,
            _0: toSerializeError(result._0)
          };
  }
}

var emptyArray = [];

var emptyMap = {
  s: emptyArray,
  u: emptyArray
};

function missingParser(param, param$1, param$2) {
  return {
          TAG: /* Failed */1,
          _0: {
            code: /* MissingParser */0,
            path: []
          }
        };
}

function missingSerializer(param, param$1, param$2) {
  return {
          TAG: /* Failed */1,
          _0: {
            code: /* MissingSerializer */1,
            path: []
          }
        };
}

function refine(struct, maybeRefineParser, maybeRefineSerializer, param) {
  if (maybeRefineParser === undefined && maybeRefineSerializer === undefined) {
    raise$1("struct factory Refine");
  }
  var currentParsers = struct.p;
  var currentSerializers = struct.s;
  var tmp;
  if (maybeRefineParser !== undefined) {
    var effect = function (input, param, param$1) {
      var reason = maybeRefineParser(input);
      if (reason !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: {
                  code: {
                    TAG: /* OperationFailed */0,
                    _0: Caml_option.valFromOption(reason)
                  },
                  path: []
                }
              };
      } else {
        return /* Refined */0;
      }
    };
    tmp = {
      s: currentParsers.s.concat([effect]),
      u: currentParsers.u
    };
  } else {
    tmp = currentParsers;
  }
  var tmp$1;
  if (maybeRefineSerializer !== undefined) {
    var effect$1 = function (input, param, param$1) {
      var reason = maybeRefineSerializer(input);
      if (reason !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: {
                  code: {
                    TAG: /* OperationFailed */0,
                    _0: Caml_option.valFromOption(reason)
                  },
                  path: []
                }
              };
      } else {
        return /* Refined */0;
      }
    };
    tmp$1 = {
      s: [effect$1].concat(currentSerializers.s),
      u: currentSerializers.u
    };
  } else {
    tmp$1 = currentSerializers;
  }
  return {
          t: struct.t,
          p: tmp,
          s: tmp$1,
          m: struct.m
        };
}

function transform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    raise$1("struct factory Transform");
  }
  var currentParsers = struct.p;
  var currentSerializers = struct.s;
  var effect;
  if (maybeTransformationParser !== undefined) {
    var transformationParser = Caml_option.valFromOption(maybeTransformationParser);
    effect = (function (input, param, param$1) {
        var ok = transformationParser(input);
        if (ok.TAG === /* Ok */0) {
          return ok;
        } else {
          return {
                  TAG: /* Failed */1,
                  _0: {
                    code: {
                      TAG: /* OperationFailed */0,
                      _0: ok._0
                    },
                    path: []
                  }
                };
        }
      });
  } else {
    effect = missingParser;
  }
  var effect$1;
  if (maybeTransformationSerializer !== undefined) {
    var transformationSerializer = Caml_option.valFromOption(maybeTransformationSerializer);
    effect$1 = (function (input, param, param$1) {
        var ok = transformationSerializer(input);
        if (ok.TAG === /* Ok */0) {
          return ok;
        } else {
          return {
                  TAG: /* Failed */1,
                  _0: {
                    code: {
                      TAG: /* OperationFailed */0,
                      _0: ok._0
                    },
                    path: []
                  }
                };
        }
      });
  } else {
    effect$1 = missingSerializer;
  }
  return {
          t: struct.t,
          p: {
            s: currentParsers.s.concat([effect]),
            u: currentParsers.u.concat([effect])
          },
          s: {
            s: [effect$1].concat(currentSerializers.s),
            u: [effect$1].concat(currentSerializers.u)
          },
          m: struct.m
        };
}

function superTransform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    raise$1("struct factory Transform");
  }
  var currentParsers = struct.p;
  var currentSerializers = struct.s;
  var effect = maybeTransformationParser !== undefined ? (function (input, struct, mode) {
        var ok = maybeTransformationParser(input, struct, mode);
        if (ok.TAG === /* Ok */0) {
          return ok;
        } else {
          return {
                  TAG: /* Failed */1,
                  _0: ok._0
                };
        }
      }) : missingParser;
  var effect$1 = maybeTransformationSerializer !== undefined ? (function (input, struct, mode) {
        var ok = maybeTransformationSerializer(input, struct, mode);
        if (ok.TAG === /* Ok */0) {
          return ok;
        } else {
          return {
                  TAG: /* Failed */1,
                  _0: ok._0
                };
        }
      }) : missingSerializer;
  return {
          t: struct.t,
          p: {
            s: currentParsers.s.concat([effect]),
            u: currentParsers.u.concat([effect])
          },
          s: {
            s: [effect$1].concat(currentSerializers.s),
            u: [effect$1].concat(currentSerializers.u)
          },
          m: struct.m
        };
}

function custom(maybeCustomParser, maybeCustomSerializer, param) {
  if (maybeCustomParser === undefined && maybeCustomSerializer === undefined) {
    raise$1("Custom struct factory");
  }
  var effect = maybeCustomParser !== undefined ? (function (input, param, mode) {
        var ok = maybeCustomParser(input, mode);
        if (ok.TAG === /* Ok */0) {
          return ok;
        } else {
          return {
                  TAG: /* Failed */1,
                  _0: ok._0
                };
        }
      }) : missingParser;
  var effects = [effect];
  var effect$1 = maybeCustomSerializer !== undefined ? (function (input, param, mode) {
        var ok = maybeCustomSerializer(input, mode);
        if (ok.TAG === /* Ok */0) {
          return ok;
        } else {
          return {
                  TAG: /* Failed */1,
                  _0: ok._0
                };
        }
      }) : missingSerializer;
  var effects$1 = [effect$1];
  return {
          t: /* Unknown */1,
          p: {
            s: effects,
            u: effects
          },
          s: {
            s: effects$1,
            u: effects$1
          },
          m: undefined
        };
}

function literalValueRefinement(input, struct, param) {
  var expectedValue = struct.t._0._0;
  if (expectedValue === input) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: make(expectedValue, input)
          };
  }
}

function transformToLiteralValue(param, struct, param$1) {
  var literalValue = struct.t._0._0;
  return {
          TAG: /* Transformed */0,
          _0: literalValue
        };
}

function parserRefinement(input, struct, param) {
  if (input === null) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function serializerTransform(param, param$1, param$2) {
  return {
          TAG: /* Transformed */0,
          _0: null
        };
}

function parserRefinement$1(input, struct, param) {
  if (input === undefined) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function serializerTransform$1(param, param$1, param$2) {
  return {
          TAG: /* Transformed */0,
          _0: undefined
        };
}

function parserRefinement$2(input, struct, param) {
  if (Number.isNaN(input)) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function serializerTransform$2(param, param$1, param$2) {
  return {
          TAG: /* Transformed */0,
          _0: NaN
        };
}

function parserRefinement$3(input, struct, param) {
  if (typeof input === "boolean") {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function parserRefinement$4(input, struct, param) {
  if (typeof input === "string") {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function parserRefinement$5(input, struct, param) {
  if (typeof input === "number") {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function parserRefinement$6(input, struct, param) {
  if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

function factory(innerLiteral, variant) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  var parserTransform = function (param, param$1, param$2) {
    return {
            TAG: /* Transformed */0,
            _0: variant
          };
  };
  var serializerRefinement = function (input, param, param$1) {
    if (input === variant) {
      return /* Refined */0;
    } else {
      return {
              TAG: /* Failed */1,
              _0: make(variant, input)
            };
    }
  };
  if (typeof innerLiteral === "number") {
    switch (innerLiteral) {
      case /* EmptyNull */0 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      serializerTransform
                    ],
                    u: [serializerTransform]
                  },
                  m: undefined
                };
      case /* EmptyOption */1 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement$1,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      serializerTransform$1
                    ],
                    u: [serializerTransform$1]
                  },
                  m: undefined
                };
      case /* NaN */2 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement$2,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      serializerTransform$2
                    ],
                    u: [serializerTransform$2]
                  },
                  m: undefined
                };
      
    }
  } else {
    switch (innerLiteral.TAG | 0) {
      case /* String */0 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement$4,
                      literalValueRefinement,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      transformToLiteralValue
                    ],
                    u: [transformToLiteralValue]
                  },
                  m: undefined
                };
      case /* Int */1 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement$6,
                      literalValueRefinement,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      transformToLiteralValue
                    ],
                    u: [transformToLiteralValue]
                  },
                  m: undefined
                };
      case /* Float */2 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement$5,
                      literalValueRefinement,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      transformToLiteralValue
                    ],
                    u: [transformToLiteralValue]
                  },
                  m: undefined
                };
      case /* Bool */3 :
          return {
                  t: tagged_t,
                  p: {
                    s: [
                      parserRefinement$3,
                      literalValueRefinement,
                      parserTransform
                    ],
                    u: [parserTransform]
                  },
                  s: {
                    s: [
                      serializerRefinement,
                      transformToLiteralValue
                    ],
                    u: [transformToLiteralValue]
                  },
                  m: undefined
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
      if (!Object.prototype.hasOwnProperty.call(innerStructsDict, key)) {
        return key
      }
    }
    return undefined
  });

function parserTransform(input, struct, mode) {
  var maybeRefinementError = mode || typeof input === "object" && !Array.isArray(input) && input !== null ? undefined : makeUnexpectedTypeError(input, struct);
  if (maybeRefinementError !== undefined) {
    return {
            TAG: /* Failed */1,
            _0: maybeRefinementError
          };
  }
  var match = struct.t;
  var fieldNames = match.fieldNames;
  var fields = match.fields;
  var newArray = [];
  var idxRef = 0;
  var maybeErrorRef;
  while(idxRef < fieldNames.length && maybeErrorRef === undefined) {
    var idx = idxRef;
    var fieldName = fieldNames[idx];
    var fieldStruct = fields[fieldName];
    var value = processInner(/* Parsing */1, input[fieldName], mode, fieldStruct);
    if (value.TAG === /* Ok */0) {
      newArray.push(value._0);
      idxRef = idxRef + 1;
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
            TAG: /* Failed */1,
            _0: error
          };
  } else {
    return {
            TAG: /* Transformed */0,
            _0: newArray.length <= 1 ? newArray[0] : newArray
          };
  }
}

var parsers_s = [parserTransform];

var parsers_u = [parserTransform];

var parsers = {
  s: parsers_s,
  u: parsers_u
};

function serializerTransform$3(input, struct, mode) {
  var match = struct.t;
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
    var unknownFieldValue = processInner(/* Serializing */0, fieldValue, mode, fieldStruct);
    if (unknownFieldValue.TAG === /* Ok */0) {
      unknown[fieldName] = unknownFieldValue._0;
      idxRef = idxRef + 1;
    } else {
      maybeErrorRef = prependLocation(unknownFieldValue._0, fieldName);
    }
  };
  var error = maybeErrorRef;
  if (error !== undefined) {
    return {
            TAG: /* Failed */1,
            _0: error
          };
  } else {
    return {
            TAG: /* Transformed */0,
            _0: unknown
          };
  }
}

var serializers_s = [serializerTransform$3];

var serializers_u = [serializerTransform$3];

var serializers = {
  s: serializers_s,
  u: serializers_u
};

function innerFactory(fieldsArray) {
  var fields = Js_dict.fromArray(fieldsArray);
  return {
          t: {
            TAG: /* Record */4,
            fields: fields,
            fieldNames: Object.keys(fields),
            unknownKeys: /* Strict */0
          },
          p: parsers,
          s: serializers,
          m: undefined
        };
}

var factory$2 = callWithArguments(innerFactory);

function strip(struct) {
  var tagged_t = struct.t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return raise("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return {
            t: {
              TAG: /* Record */4,
              fields: tagged_t.fields,
              fieldNames: tagged_t.fieldNames,
              unknownKeys: /* Strip */1
            },
            p: struct.p,
            s: struct.s,
            m: struct.m
          };
  }
}

function strict(struct) {
  var tagged_t = struct.t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return raise("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return {
            t: {
              TAG: /* Record */4,
              fields: tagged_t.fields,
              fieldNames: tagged_t.fieldNames,
              unknownKeys: /* Strict */0
            },
            p: struct.p,
            s: struct.s,
            m: struct.m
          };
  }
}

var effects = [(function (input, struct, param) {
      return {
              TAG: /* Failed */1,
              _0: makeUnexpectedTypeError(input, struct)
            };
    })];

var effectsMap = {
  s: effects,
  u: emptyArray
};

function factory$3(param) {
  return {
          t: /* Never */0,
          p: effectsMap,
          s: effectsMap,
          m: undefined
        };
}

function factory$4(param) {
  return {
          t: /* Unknown */1,
          p: emptyMap,
          s: emptyMap,
          m: undefined
        };
}

var cuidRegex = /^c[^\s-]{8,}$/i;

var uuidRegex = /^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i;

var emailRegex = /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;

function parserRefinement$7(input, struct, param) {
  if (typeof input === "string") {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

var parsers_s$1 = [parserRefinement$7];

var parsers$1 = {
  s: parsers_s$1,
  u: emptyArray
};

function factory$5(param) {
  return {
          t: /* String */2,
          p: parsers$1,
          s: emptyMap,
          m: undefined
        };
}

function min(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length < length) {
      return Belt_Option.getWithDefault(maybeMessage, "String must be " + length.toString() + " or more characters long");
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function max(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length > length) {
      return Belt_Option.getWithDefault(maybeMessage, "String must be " + length.toString() + " or fewer characters long");
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function length(struct, maybeMessage, length$1) {
  var refiner = function (value) {
    if (value.length === length$1) {
      return ;
    } else {
      return Belt_Option.getWithDefault(maybeMessage, "String must be exactly " + length$1.toString() + " characters long");
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function email(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid email address";
  var refiner = function (value) {
    if (emailRegex.test(value)) {
      return ;
    } else {
      return message;
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function uuid(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid UUID";
  var refiner = function (value) {
    if (uuidRegex.test(value)) {
      return ;
    } else {
      return message;
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function cuid(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid CUID";
  var refiner = function (value) {
    if (cuidRegex.test(value)) {
      return ;
    } else {
      return message;
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function url(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid url";
  var refiner = function (value) {
    var tmp;
    try {
      new URL(value);
      tmp = true;
    }
    catch (exn){
      tmp = false;
    }
    if (tmp) {
      return ;
    } else {
      return message;
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function pattern(struct, messageOpt, re) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid";
  var refiner = function (value) {
    re.lastIndex = 0;
    if (re.test(value)) {
      return ;
    } else {
      return message;
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function trimmed(struct, param) {
  var transformer = function (value) {
    return {
            TAG: /* Ok */0,
            _0: value.trim()
          };
  };
  return transform(struct, transformer, transformer, undefined);
}

function parserRefinement$8(input, struct, param) {
  if (typeof input === "boolean") {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

var parsers_s$2 = [parserRefinement$8];

var parsers$2 = {
  s: parsers_s$2,
  u: emptyArray
};

function factory$6(param) {
  return {
          t: /* Bool */5,
          p: parsers$2,
          s: emptyMap,
          m: undefined
        };
}

function parserRefinement$9(input, struct, param) {
  if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

var parsers_s$3 = [parserRefinement$9];

var parsers$3 = {
  s: parsers_s$3,
  u: emptyArray
};

function factory$7(param) {
  return {
          t: /* Int */3,
          p: parsers$3,
          s: emptyMap,
          m: undefined
        };
}

function min$1(struct, maybeMessage, thanValue) {
  var refiner = function (value) {
    if (value >= thanValue) {
      return ;
    } else {
      return Belt_Option.getWithDefault(maybeMessage, "Number must be greater than or equal to " + thanValue.toString());
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function max$1(struct, maybeMessage, thanValue) {
  var refiner = function (value) {
    if (value <= thanValue) {
      return ;
    } else {
      return Belt_Option.getWithDefault(maybeMessage, "Number must be lower than or equal to " + thanValue.toString());
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

function parserRefinement$10(input, struct, param) {
  if (typeof input === "number" && !Number.isNaN(input)) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

var parsers_s$4 = [parserRefinement$10];

var parsers$4 = {
  s: parsers_s$4,
  u: emptyArray
};

function factory$8(param) {
  return {
          t: /* Float */4,
          p: parsers$4,
          s: emptyMap,
          m: undefined
        };
}

function parserRefinement$11(input, struct, param) {
  var factory = struct.t._0;
  if (factoryOf(factory, input) && !Number.isNaN(input.getTime())) {
    return /* Refined */0;
  } else {
    return {
            TAG: /* Failed */1,
            _0: makeUnexpectedTypeError(input, struct)
          };
  }
}

var parsers_s$5 = [parserRefinement$11];

var parsers$5 = {
  s: parsers_s$5,
  u: emptyArray
};

function factory$9(param) {
  return {
          t: {
            TAG: /* Instance */10,
            _0: Date
          },
          p: parsers$5,
          s: emptyMap,
          m: undefined
        };
}

var parserEffects = [(function (input, struct, mode) {
      if (input === null) {
        return {
                TAG: /* Transformed */0,
                _0: undefined
              };
      }
      var innerStruct = struct.t._0;
      var value = processInner(/* Parsing */1, input, mode, innerStruct);
      if (value.TAG === /* Ok */0) {
        return {
                TAG: /* Transformed */0,
                _0: Caml_option.some(value._0)
              };
      } else {
        return value;
      }
    })];

var parsers$6 = {
  s: parserEffects,
  u: parserEffects
};

var serializerEffects = [(function (input, struct, mode) {
      if (input === undefined) {
        return {
                TAG: /* Transformed */0,
                _0: null
              };
      }
      var innerStruct = struct.t._0;
      return processInner(/* Serializing */0, Caml_option.valFromOption(input), mode, innerStruct);
    })];

var serializers$1 = {
  s: serializerEffects,
  u: serializerEffects
};

function factory$10(innerStruct) {
  return {
          t: {
            TAG: /* Null */2,
            _0: innerStruct
          },
          p: parsers$6,
          s: serializers$1,
          m: undefined
        };
}

var parserEffects$1 = [(function (input, struct, mode) {
      if (input === undefined) {
        return /* Refined */0;
      }
      var innerStruct = struct.t._0;
      var v = processInner(/* Parsing */1, Caml_option.valFromOption(input), mode, innerStruct);
      if (v.TAG === /* Ok */0) {
        return {
                TAG: /* Transformed */0,
                _0: Caml_option.some(v._0)
              };
      } else {
        return v;
      }
    })];

var parsers$7 = {
  s: parserEffects$1,
  u: parserEffects$1
};

var serializerEffects$1 = [(function (input, struct, mode) {
      if (input === undefined) {
        return /* Refined */0;
      }
      var innerStruct = struct.t._0;
      return processInner(/* Serializing */0, Caml_option.valFromOption(input), mode, innerStruct);
    })];

var serializers$2 = {
  s: serializerEffects$1,
  u: serializerEffects$1
};

function factory$11(innerStruct) {
  return {
          t: {
            TAG: /* Option */1,
            _0: innerStruct
          },
          p: parsers$7,
          s: serializers$2,
          m: undefined
        };
}

var parserEffects$2 = [(function (input, struct, mode) {
      if (input === undefined) {
        return /* Refined */0;
      }
      var match = struct.t;
      var v = processInner(/* Parsing */1, Caml_option.valFromOption(input), mode, match.struct);
      if (v.TAG === /* Ok */0) {
        return {
                TAG: /* Transformed */0,
                _0: Caml_option.some(v._0)
              };
      } else {
        return v;
      }
    })];

var parsers$8 = {
  s: parserEffects$2,
  u: parserEffects$2
};

var serializerEffects$2 = [(function (input, struct, mode) {
      if (input === undefined) {
        return /* Refined */0;
      }
      var match = struct.t;
      return processInner(/* Serializing */0, Caml_option.valFromOption(input), mode, match.struct);
    })];

var serializers$3 = {
  s: serializerEffects$2,
  u: serializerEffects$2
};

function factory$12(maybeMessage, innerStruct) {
  return {
          t: {
            TAG: /* Deprecated */8,
            struct: innerStruct,
            maybeMessage: maybeMessage
          },
          p: parsers$8,
          s: serializers$3,
          m: undefined
        };
}

var parserEffects$3 = [(function (input, struct, mode) {
      var maybeRefinementError = mode || Array.isArray(input) ? undefined : makeUnexpectedTypeError(input, struct);
      if (maybeRefinementError !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: maybeRefinementError
              };
      }
      var innerStruct = struct.t._0;
      var newArray = [];
      var idxRef = 0;
      var maybeErrorRef;
      while(idxRef < input.length && maybeErrorRef === undefined) {
        var idx = idxRef;
        var innerValue = input[idx];
        var value = processInner(/* Parsing */1, innerValue, mode, innerStruct);
        if (value.TAG === /* Ok */0) {
          newArray.push(value._0);
          idxRef = idxRef + 1;
        } else {
          maybeErrorRef = prependLocation(value._0, idx.toString());
        }
      };
      var error = maybeErrorRef;
      if (error !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: error
              };
      } else {
        return {
                TAG: /* Transformed */0,
                _0: newArray
              };
      }
    })];

var parsers$9 = {
  s: parserEffects$3,
  u: parserEffects$3
};

var serializerEffects$3 = [(function (input, struct, mode) {
      var innerStruct = struct.t._0;
      var newArray = [];
      var idxRef = 0;
      var maybeErrorRef;
      while(idxRef < input.length && maybeErrorRef === undefined) {
        var idx = idxRef;
        var innerValue = input[idx];
        var value = processInner(/* Serializing */0, innerValue, mode, innerStruct);
        if (value.TAG === /* Ok */0) {
          newArray.push(value._0);
          idxRef = idxRef + 1;
        } else {
          maybeErrorRef = prependLocation(value._0, idx.toString());
        }
      };
      var error = maybeErrorRef;
      if (error !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: error
              };
      } else {
        return {
                TAG: /* Transformed */0,
                _0: newArray
              };
      }
    })];

var serializers$4 = {
  s: serializerEffects$3,
  u: serializerEffects$3
};

function factory$13(innerStruct) {
  return {
          t: {
            TAG: /* Array */3,
            _0: innerStruct
          },
          p: parsers$9,
          s: serializers$4,
          m: undefined
        };
}

function min$2(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length < length) {
      return Belt_Option.getWithDefault(maybeMessage, "Array must be " + length.toString() + " or more items long");
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function max$2(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length > length) {
      return Belt_Option.getWithDefault(maybeMessage, "Array must be " + length.toString() + " or fewer items long");
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function length$1(struct, maybeMessage, length$2) {
  var refiner = function (value) {
    if (value.length === length$2) {
      return ;
    } else {
      return Belt_Option.getWithDefault(maybeMessage, "Array must be exactly " + length$2.toString() + " items long");
    }
  };
  return refine(struct, refiner, refiner, undefined);
}

var parserEffects$4 = [(function (input, struct, mode) {
      var maybeRefinementError = mode || typeof input === "object" && !Array.isArray(input) && input !== null ? undefined : makeUnexpectedTypeError(input, struct);
      if (maybeRefinementError !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: maybeRefinementError
              };
      }
      var innerStruct = struct.t._0;
      var newDict = {};
      var keys = Object.keys(input);
      var idxRef = 0;
      var maybeErrorRef;
      while(idxRef < keys.length && maybeErrorRef === undefined) {
        var idx = idxRef;
        var key = keys[idx];
        var innerValue = input[key];
        var value = processInner(/* Parsing */1, innerValue, mode, innerStruct);
        if (value.TAG === /* Ok */0) {
          newDict[key] = value._0;
          idxRef = idxRef + 1;
        } else {
          maybeErrorRef = prependLocation(value._0, key);
        }
      };
      var error = maybeErrorRef;
      if (error !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: error
              };
      } else {
        return {
                TAG: /* Transformed */0,
                _0: newDict
              };
      }
    })];

var parsers$10 = {
  s: parserEffects$4,
  u: parserEffects$4
};

var serializerEffects$4 = [(function (input, struct, mode) {
      var innerStruct = struct.t._0;
      var newDict = {};
      var keys = Object.keys(input);
      var idxRef = 0;
      var maybeErrorRef;
      while(idxRef < keys.length && maybeErrorRef === undefined) {
        var idx = idxRef;
        var key = keys[idx];
        var innerValue = input[key];
        var value = processInner(/* Serializing */0, innerValue, mode, innerStruct);
        if (value.TAG === /* Ok */0) {
          newDict[key] = value._0;
          idxRef = idxRef + 1;
        } else {
          maybeErrorRef = prependLocation(value._0, key);
        }
      };
      var error = maybeErrorRef;
      if (error !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: error
              };
      } else {
        return {
                TAG: /* Transformed */0,
                _0: newDict
              };
      }
    })];

var serializers$5 = {
  s: serializerEffects$4,
  u: serializerEffects$4
};

function factory$14(innerStruct) {
  return {
          t: {
            TAG: /* Dict */7,
            _0: innerStruct
          },
          p: parsers$10,
          s: serializers$5,
          m: undefined
        };
}

var parserEffects$5 = [(function (input, struct, mode) {
      var match = struct.t;
      var maybeOutput = processInner(/* Parsing */1, input, mode, match.struct);
      if (maybeOutput.TAG !== /* Ok */0) {
        return maybeOutput;
      }
      var maybeOutput$1 = maybeOutput._0;
      return {
              TAG: /* Transformed */0,
              _0: maybeOutput$1 !== undefined ? Caml_option.valFromOption(maybeOutput$1) : match.value
            };
    })];

var parsers$11 = {
  s: parserEffects$5,
  u: parserEffects$5
};

var serializerEffects$5 = [(function (input, struct, mode) {
      var match = struct.t;
      return processInner(/* Serializing */0, Caml_option.some(input), mode, match.struct);
    })];

var serializers$6 = {
  s: serializerEffects$5,
  u: serializerEffects$5
};

function factory$15(innerStruct, defaultValue) {
  return {
          t: {
            TAG: /* Default */9,
            struct: innerStruct,
            value: defaultValue
          },
          p: parsers$11,
          s: serializers$6,
          m: undefined
        };
}

var parserEffects$6 = [(function (input, struct, mode) {
      var innerStructs = struct.t._0;
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
                TAG: /* Failed */1,
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
        var value = processInner(/* Parsing */1, innerValue, mode, innerStruct);
        if (value.TAG === /* Ok */0) {
          newArray.push(value._0);
          idxRef = idxRef + 1;
        } else {
          maybeErrorRef = prependLocation(value._0, idx.toString());
        }
      };
      var error = maybeErrorRef;
      if (error !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: error
              };
      } else {
        return {
                TAG: /* Transformed */0,
                _0: numberOfStructs !== 0 ? (
                    numberOfStructs !== 1 ? newArray : newArray[0]
                  ) : undefined
              };
      }
    })];

var parsers$12 = {
  s: parserEffects$6,
  u: parserEffects$6
};

var serializerEffects$6 = [(function (input, struct, mode) {
      var innerStructs = struct.t._0;
      var numberOfStructs = innerStructs.length;
      var inputArray = numberOfStructs === 1 ? [input] : input;
      var newArray = [];
      var idxRef = 0;
      var maybeErrorRef;
      while(idxRef < numberOfStructs && maybeErrorRef === undefined) {
        var idx = idxRef;
        var innerValue = inputArray[idx];
        var innerStruct = innerStructs[idx];
        var value = processInner(/* Serializing */0, innerValue, mode, innerStruct);
        if (value.TAG === /* Ok */0) {
          newArray.push(value._0);
          idxRef = idxRef + 1;
        } else {
          maybeErrorRef = prependLocation(value._0, idx.toString());
        }
      };
      var error = maybeErrorRef;
      if (error !== undefined) {
        return {
                TAG: /* Failed */1,
                _0: error
              };
      } else {
        return {
                TAG: /* Transformed */0,
                _0: newArray
              };
      }
    })];

var serializers$7 = {
  s: serializerEffects$6,
  u: serializerEffects$6
};

function innerFactory$1(structs) {
  return {
          t: {
            TAG: /* Tuple */5,
            _0: structs
          },
          p: parsers$12,
          s: serializers$7,
          m: undefined
        };
}

var factory$16 = callWithArguments(innerFactory$1);

var parserEffects$7 = [(function (input, struct, param) {
      var innerStructs = struct.t._0;
      var idxRef = 0;
      var maybeErrorsRef;
      var maybeOkRef;
      while(idxRef < innerStructs.length && maybeOkRef === undefined) {
        var idx = idxRef;
        var innerStruct = innerStructs[idx];
        var ok = processInner(/* Parsing */1, input, /* Safe */0, innerStruct);
        if (ok.TAG === /* Ok */0) {
          maybeOkRef = ok;
        } else {
          var v = maybeErrorsRef;
          var errors;
          if (v !== undefined) {
            errors = v;
          } else {
            var newErrosArray = [];
            maybeErrorsRef = newErrosArray;
            errors = newErrosArray;
          }
          errors.push(ok._0);
          idxRef = idxRef + 1;
        }
      };
      var ok$1 = maybeOkRef;
      if (ok$1 !== undefined) {
        return ok$1;
      }
      var errors$1 = maybeErrorsRef;
      if (errors$1 === undefined) {
        return undefined;
      }
      var code = {
        TAG: /* InvalidUnion */5,
        _0: errors$1.map(toParseError)
      };
      return {
              TAG: /* Failed */1,
              _0: {
                code: code,
                path: []
              }
            };
    })];

var parsers$13 = {
  s: parserEffects$7,
  u: parserEffects$7
};

var serializerEffects$7 = [(function (input, struct, param) {
      var innerStructs = struct.t._0;
      var idxRef = 0;
      var maybeLastErrorRef;
      var maybeOkRef;
      while(idxRef < innerStructs.length && maybeOkRef === undefined) {
        var idx = idxRef;
        var innerStruct = innerStructs[idx];
        var ok = processInner(/* Serializing */0, input, /* Safe */0, innerStruct);
        if (ok.TAG === /* Ok */0) {
          maybeOkRef = ok;
        } else {
          maybeLastErrorRef = ok;
          idxRef = idxRef + 1;
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
    })];

var serializers$8 = {
  s: serializerEffects$7,
  u: serializerEffects$7
};

function factory$17(structs) {
  if (structs.length < 2) {
    raise("A Union struct factory require at least two structs");
  }
  return {
          t: {
            TAG: /* Union */6,
            _0: structs
          },
          p: parsers$13,
          s: serializers$8,
          m: undefined
        };
}

function json(innerStruct) {
  return superTransform(factory$5(undefined), (function (value, param, mode) {
                var result;
                var exit = 0;
                var json;
                try {
                  json = JSON.parse(value);
                  exit = 1;
                }
                catch (raw_obj){
                  var obj = Caml_js_exceptions.internalToOCamlException(raw_obj);
                  if (obj.RE_EXN_ID === Js_exn.$$Error) {
                    result = {
                      TAG: /* Error */1,
                      _0: make$1(Belt_Option.getWithDefault(obj._1.message, "Failed to parse JSON"))
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
                if (result.TAG !== /* Ok */0) {
                  return result;
                }
                var parsedJson = result._0;
                return parseWith(parsedJson, mode, innerStruct);
              }), (function (transformed, param, mode) {
                var result = serializeWith(transformed, mode, innerStruct);
                if (result.TAG === /* Ok */0) {
                  return {
                          TAG: /* Ok */0,
                          _0: JSON.stringify(result._0)
                        };
                } else {
                  return result;
                }
              }), undefined);
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

var date = factory$9;

var literal = factory$1;

var literalVariant = factory;

var array = factory$13;

var dict = factory$14;

var option = factory$11;

var $$null = factory$10;

var deprecated = factory$12;

var $$default = factory$15;

var union = factory$17;

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
  factory: factory$16
};

var tuple0 = factory$16;

var tuple1 = factory$16;

var tuple2 = factory$16;

var tuple3 = factory$16;

var tuple4 = factory$16;

var tuple5 = factory$16;

var tuple6 = factory$16;

var tuple7 = factory$16;

var tuple8 = factory$16;

var tuple9 = factory$16;

var tuple10 = factory$16;

var $$String = {
  min: min,
  max: max,
  length: length,
  email: email,
  uuid: uuid,
  cuid: cuid,
  url: url,
  pattern: pattern,
  trimmed: trimmed
};

var Int = {
  min: min$1,
  max: max$1
};

var Float = {
  min: min$1,
  max: max$1
};

var $$Array = {
  min: min$2,
  max: max$2,
  length: length$1
};

function MakeMetadata(funarg) {
  var get = function (struct) {
    var option = struct.m;
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
    var currentContent = struct.m;
    var existingContent = currentContent !== undefined ? Caml_option.valFromOption(currentContent) : ({});
    return {
            t: struct.t,
            p: struct.p,
            s: struct.s,
            m: Caml_option.some(dictUnsafeSet(existingContent, funarg.namespace, content))
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
exports.date = date;
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
exports.$$String = $$String;
exports.Int = Int;
exports.Float = Float;
exports.$$Array = $$Array;
exports.Result = Result;
exports.MakeMetadata = MakeMetadata;
/*  Not a pure module */
