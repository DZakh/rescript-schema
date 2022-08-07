'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Js_dict = require("rescript/lib/js/js_dict.js");
var Js_types = require("rescript/lib/js/js_types.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_exceptions = require("rescript/lib/js/caml_exceptions.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

function factoryOf(self, data) {
  return (data instanceof self);
}

function callWithArguments(fn) {
  return (function(){return fn(arguments)});
}

var $$throw = (function(exn){throw exn});

class RescriptStructError extends Error {
    constructor(message) {
      super(message);
      this.name = "RescriptStructError";
    }
  }
;

var panic = (function(message){throw new RescriptStructError(message)});

var Exception = /* @__PURE__ */Caml_exceptions.create("S.Error.Internal.Exception");

function raise(code) {
  throw {
        RE_EXN_ID: Exception,
        _1: {
          code: code,
          path: []
        },
        Error: new Error()
      };
}

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

function raise$1(expected, received) {
  return raise({
              TAG: /* UnexpectedValue */2,
              expected: stringify(expected),
              received: stringify(received)
            });
}

function panic$1($$location) {
  return panic("For a " + $$location + " either a parser, or a serializer is required");
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

function make(reason) {
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
    switch (reason) {
      case /* MissingParser */0 :
          return "Struct parser is missing";
      case /* MissingSerializer */1 :
          return "Struct serializer is missing";
      case /* UnexpectedAsync */2 :
          return "Encountered unexpected asynchronous transform or refine. Use parseAsyncWith instead of parseWith";
      
    }
  } else {
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
          var array = reason._0.map(function (error) {
                var reason = toReason(nestedLevel + 1, error);
                var nonEmptyPath = error.path;
                var $$location = nonEmptyPath.length !== 0 ? "Failed at " + formatPath(nonEmptyPath) + ". " : "";
                return "- " + $$location + reason;
              });
          var reasons = Array.from(new Set(array));
          return "Invalid union with following errors" + lineBreak + reasons.join(lineBreak);
      
    }
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

function raiseUnexpectedTypeError(input, struct) {
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
  return raise({
              TAG: /* UnexpectedType */1,
              expected: expected,
              received: received
            });
}

function makeOperation(struct, actions, mode) {
  if (actions.length === 0) {
    return /* Noop */0;
  }
  var firstSyncActions = [];
  var maybeAsyncActionIdxRef;
  var idxRef = 0;
  while(idxRef < actions.length && maybeAsyncActionIdxRef === undefined) {
    var idx = idxRef;
    var action = actions[idx];
    var exit = 0;
    switch (action.TAG | 0) {
      case /* AsyncRefine */0 :
      case /* AsyncTransform */1 :
          maybeAsyncActionIdxRef = idx;
          break;
      case /* SyncTransform */2 :
      case /* SyncRefine */3 :
          exit = 1;
          break;
      
    }
    if (exit === 1) {
      firstSyncActions.push(action);
      idxRef = idxRef + 1;
    }
    
  };
  var option = maybeAsyncActionIdxRef;
  var maybeAsyncAffectedActions = option !== undefined ? Caml_option.some(actions.slice(Caml_option.valFromOption(option))) : undefined;
  var syncOperation = function (input) {
    var tempOuputRef = input;
    for(var idx = 0 ,idx_finish = firstSyncActions.length; idx < idx_finish; ++idx){
      var firstSyncAction = firstSyncActions[idx];
      switch (firstSyncAction.TAG | 0) {
        case /* AsyncRefine */0 :
        case /* AsyncTransform */1 :
            panic("Unreachable");
            break;
        case /* SyncTransform */2 :
            var newValue = firstSyncAction._0(tempOuputRef, struct, mode);
            tempOuputRef = newValue;
            break;
        case /* SyncRefine */3 :
            firstSyncAction._0(tempOuputRef, struct, mode);
            break;
        
      }
    }
    return tempOuputRef;
  };
  if (maybeAsyncAffectedActions !== undefined) {
    return {
            TAG: /* Async */1,
            _0: (function (input) {
                var tempOuputRef = Promise.resolve(syncOperation(input));
                for(var idx = 0 ,idx_finish = maybeAsyncAffectedActions.length; idx < idx_finish; ++idx){
                  var action = maybeAsyncAffectedActions[idx];
                  tempOuputRef = tempOuputRef.then((function(action){
                      return function (tempOutput) {
                        switch (action.TAG | 0) {
                          case /* AsyncRefine */0 :
                              return action._0(tempOutput, struct, mode).then(function (param) {
                                          return tempOutput;
                                        });
                          case /* AsyncTransform */1 :
                              return action._0(tempOutput, struct, mode);
                          case /* SyncTransform */2 :
                              return Promise.resolve(action._0(tempOutput, struct, mode));
                          case /* SyncRefine */3 :
                              action._0(tempOutput, struct, mode);
                              return Promise.resolve(tempOutput);
                          
                        }
                      }
                      }(action)));
                }
                return tempOuputRef;
              })
          };
  } else {
    return {
            TAG: /* Sync */0,
            _0: syncOperation
          };
  }
}

function make$1(tagged_t, safeParseActions, migrationParseActions, serializeActions, maybeMetadata, param) {
  var struct_s = undefined;
  var struct_p = undefined;
  var struct = {
    t: tagged_t,
    sp: safeParseActions,
    mp: migrationParseActions,
    sa: serializeActions,
    s: struct_s,
    p: struct_p,
    m: maybeMetadata
  };
  return {
          t: tagged_t,
          sp: safeParseActions,
          mp: migrationParseActions,
          sa: serializeActions,
          s: makeOperation(struct, serializeActions, /* Safe */0),
          p: [
            makeOperation(struct, safeParseActions, /* Safe */0),
            makeOperation(struct, migrationParseActions, /* Migration */1)
          ],
          m: maybeMetadata
        };
}

function parseWith(any, modeOpt, struct) {
  var mode = modeOpt !== undefined ? modeOpt : /* Safe */0;
  try {
    var fn = struct.p[mode];
    if (typeof fn === "number") {
      return {
              TAG: /* Ok */0,
              _0: any
            };
    } else if (fn.TAG === /* Sync */0) {
      return {
              TAG: /* Ok */0,
              _0: fn._0(any)
            };
    } else {
      return raise(/* UnexpectedAsync */2);
    }
  }
  catch (raw_internalError){
    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
    if (internalError.RE_EXN_ID === Exception) {
      return {
              TAG: /* Error */1,
              _0: toParseError(internalError._1)
            };
    }
    throw internalError;
  }
}

function parseAsyncWith(any, modeOpt, struct) {
  var mode = modeOpt !== undefined ? modeOpt : /* Safe */0;
  try {
    var fn = struct.p[mode];
    if (typeof fn === "number") {
      return {
              TAG: /* Ok */0,
              _0: Promise.resolve({
                    TAG: /* Ok */0,
                    _0: any
                  })
            };
    } else if (fn.TAG === /* Sync */0) {
      return {
              TAG: /* Ok */0,
              _0: Promise.resolve({
                    TAG: /* Ok */0,
                    _0: fn._0(any)
                  })
            };
    } else {
      return {
              TAG: /* Ok */0,
              _0: fn._0(any).then(function (value) {
                      return {
                              TAG: /* Ok */0,
                              _0: value
                            };
                    }).catch(function (exn) {
                    if (exn.RE_EXN_ID === Exception) {
                      return {
                              TAG: /* Error */1,
                              _0: toParseError(exn._1)
                            };
                    } else {
                      return $$throw(exn);
                    }
                  })
            };
    }
  }
  catch (raw_internalError){
    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
    if (internalError.RE_EXN_ID === Exception) {
      return {
              TAG: /* Error */1,
              _0: toParseError(internalError._1)
            };
    }
    throw internalError;
  }
}

function serializeWith(value, struct) {
  try {
    var fn = struct.s;
    var tmp;
    tmp = typeof fn === "number" ? value : (
        fn.TAG === /* Sync */0 ? fn._0(value) : panic("Unreachable")
      );
    return {
            TAG: /* Ok */0,
            _0: tmp
          };
  }
  catch (raw_internalError){
    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
    if (internalError.RE_EXN_ID === Exception) {
      return {
              TAG: /* Error */1,
              _0: toSerializeError(internalError._1)
            };
    }
    throw internalError;
  }
}

var emptyArray = [];

var missingParser = {
  TAG: /* SyncRefine */3,
  _0: (function (param, param$1, param$2) {
      return raise(/* MissingParser */0);
    })
};

var missingSerializer = {
  TAG: /* SyncRefine */3,
  _0: (function (param, param$1, param$2) {
      return raise(/* MissingSerializer */1);
    })
};

function refine(struct, maybeRefineParser, maybeRefineSerializer, param) {
  if (maybeRefineParser === undefined && maybeRefineSerializer === undefined) {
    panic$1("struct factory Refine");
  }
  var fn = function (refineParser) {
    return {
            TAG: /* SyncRefine */3,
            _0: (function (input, param, param$1) {
                var reason = refineParser(input);
                if (reason !== undefined) {
                  return raise({
                              TAG: /* OperationFailed */0,
                              _0: Caml_option.valFromOption(reason)
                            });
                }
                
              })
          };
  };
  var maybeParseAction = maybeRefineParser !== undefined ? Caml_option.some(fn(Caml_option.valFromOption(maybeRefineParser))) : undefined;
  var tmp;
  if (maybeRefineSerializer !== undefined) {
    var action = {
      TAG: /* SyncRefine */3,
      _0: (function (input, param, param$1) {
          var reason = maybeRefineSerializer(input);
          if (reason !== undefined) {
            return raise({
                        TAG: /* OperationFailed */0,
                        _0: Caml_option.valFromOption(reason)
                      });
          }
          
        })
    };
    tmp = [action].concat(struct.sa);
  } else {
    tmp = struct.sa;
  }
  return make$1(struct.t, maybeParseAction !== undefined ? struct.sp.concat([maybeParseAction]) : struct.sp, maybeParseAction !== undefined ? struct.mp.concat([maybeParseAction]) : struct.mp, tmp, struct.m, undefined);
}

function asyncRefine(struct, parser, param) {
  var parseAction = {
    TAG: /* AsyncRefine */0,
    _0: (function (input, param, param$1) {
        return parser(input).then(function (result) {
                    if (result !== undefined) {
                      return raise({
                                  TAG: /* OperationFailed */0,
                                  _0: result
                                });
                    }
                    
                  });
      })
  };
  return make$1(struct.t, struct.sp.concat([parseAction]), struct.mp.concat([parseAction]), struct.sa, struct.m, undefined);
}

function transform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    panic$1("struct factory Transform");
  }
  var parseAction;
  if (maybeTransformationParser !== undefined) {
    var transformationParser = Caml_option.valFromOption(maybeTransformationParser);
    parseAction = {
      TAG: /* SyncTransform */2,
      _0: (function (input, param, param$1) {
          var transformed = transformationParser(input);
          if (transformed.TAG === /* Ok */0) {
            return transformed._0;
          } else {
            return raise({
                        TAG: /* OperationFailed */0,
                        _0: transformed._0
                      });
          }
        })
    };
  } else {
    parseAction = missingParser;
  }
  var action;
  if (maybeTransformationSerializer !== undefined) {
    var transformationSerializer = Caml_option.valFromOption(maybeTransformationSerializer);
    action = {
      TAG: /* SyncTransform */2,
      _0: (function (input, param, param$1) {
          var value = transformationSerializer(input);
          if (value.TAG === /* Ok */0) {
            return value._0;
          } else {
            return raise({
                        TAG: /* OperationFailed */0,
                        _0: value._0
                      });
          }
        })
    };
  } else {
    action = missingSerializer;
  }
  return make$1(struct.t, struct.sp.concat([parseAction]), struct.mp.concat([parseAction]), [action].concat(struct.sa), struct.m, undefined);
}

function superTransform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    panic$1("struct factory Transform");
  }
  var parseAction;
  if (maybeTransformationParser !== undefined) {
    var transformationParser = Caml_option.valFromOption(maybeTransformationParser);
    parseAction = {
      TAG: /* SyncTransform */2,
      _0: (function (input, struct, mode) {
          var transformed = transformationParser(input, struct, mode);
          if (transformed.TAG === /* Ok */0) {
            return transformed._0;
          }
          throw {
                RE_EXN_ID: Exception,
                _1: transformed._0,
                Error: new Error()
              };
        })
    };
  } else {
    parseAction = missingParser;
  }
  var action;
  if (maybeTransformationSerializer !== undefined) {
    var transformationSerializer = Caml_option.valFromOption(maybeTransformationSerializer);
    action = {
      TAG: /* SyncTransform */2,
      _0: (function (input, param, param$1) {
          var value = transformationSerializer(input, struct);
          if (value.TAG === /* Ok */0) {
            return value._0;
          }
          throw {
                RE_EXN_ID: Exception,
                _1: value._0,
                Error: new Error()
              };
        })
    };
  } else {
    action = missingSerializer;
  }
  return make$1(struct.t, struct.sp.concat([parseAction]), struct.mp.concat([parseAction]), [action].concat(struct.sa), struct.m, undefined);
}

function custom(maybeCustomParser, maybeCustomSerializer, param) {
  if (maybeCustomParser === undefined && maybeCustomSerializer === undefined) {
    panic$1("Custom struct factory");
  }
  var parseActions = [maybeCustomParser !== undefined ? ({
          TAG: /* SyncTransform */2,
          _0: (function (input, param, mode) {
              var value = maybeCustomParser(input, mode);
              if (value.TAG === /* Ok */0) {
                return value._0;
              }
              throw {
                    RE_EXN_ID: Exception,
                    _1: value._0,
                    Error: new Error()
                  };
            })
        }) : missingParser];
  return make$1(/* Unknown */1, parseActions, parseActions, [maybeCustomSerializer !== undefined ? ({
                    TAG: /* SyncTransform */2,
                    _0: (function (input, param, param$1) {
                        var value = maybeCustomSerializer(input);
                        if (value.TAG === /* Ok */0) {
                          return value._0;
                        }
                        throw {
                              RE_EXN_ID: Exception,
                              _1: value._0,
                              Error: new Error()
                            };
                      })
                  }) : missingSerializer], undefined, undefined);
}

var literalValueRefinement = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      var expectedValue = struct.t._0._0;
      if (expectedValue !== input) {
        return raise$1(expectedValue, input);
      }
      
    })
};

var transformToLiteralValue = {
  TAG: /* SyncTransform */2,
  _0: (function (param, struct, param$1) {
      return struct.t._0._0;
    })
};

var parserRefinement = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (input !== null) {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

var serializerTransform = {
  TAG: /* SyncTransform */2,
  _0: (function (param, param$1, param$2) {
      return null;
    })
};

var parserRefinement$1 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (input !== undefined) {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

var serializerTransform$1 = {
  TAG: /* SyncTransform */2,
  _0: (function (param, param$1, param$2) {
      
    })
};

var parserRefinement$2 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (!Number.isNaN(input)) {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

var serializerTransform$2 = {
  TAG: /* SyncTransform */2,
  _0: (function (param, param$1, param$2) {
      return NaN;
    })
};

var parserRefinement$3 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (typeof input !== "boolean") {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

var parserRefinement$4 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (typeof input !== "string") {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

var parserRefinement$5 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (typeof input !== "number") {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

var parserRefinement$6 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (!(typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input))) {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

function factory(innerLiteral, variant) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  var parserTransform = {
    TAG: /* SyncTransform */2,
    _0: (function (param, param$1, param$2) {
        return variant;
      })
  };
  var serializerRefinement = {
    TAG: /* SyncRefine */3,
    _0: (function (input, param, param$1) {
        if (input !== variant) {
          return raise$1(variant, input);
        }
        
      })
  };
  if (typeof innerLiteral === "number") {
    switch (innerLiteral) {
      case /* EmptyNull */0 :
          return make$1(tagged_t, [
                      parserRefinement,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      serializerTransform
                    ], undefined, undefined);
      case /* EmptyOption */1 :
          return make$1(tagged_t, [
                      parserRefinement$1,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      serializerTransform$1
                    ], undefined, undefined);
      case /* NaN */2 :
          return make$1(tagged_t, [
                      parserRefinement$2,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      serializerTransform$2
                    ], undefined, undefined);
      
    }
  } else {
    switch (innerLiteral.TAG | 0) {
      case /* String */0 :
          return make$1(tagged_t, [
                      parserRefinement$4,
                      literalValueRefinement,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      transformToLiteralValue
                    ], undefined, undefined);
      case /* Int */1 :
          return make$1(tagged_t, [
                      parserRefinement$6,
                      literalValueRefinement,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      transformToLiteralValue
                    ], undefined, undefined);
      case /* Float */2 :
          return make$1(tagged_t, [
                      parserRefinement$5,
                      literalValueRefinement,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      transformToLiteralValue
                    ], undefined, undefined);
      case /* Bool */3 :
          return make$1(tagged_t, [
                      parserRefinement$3,
                      literalValueRefinement,
                      parserTransform
                    ], [parserTransform], [
                      serializerRefinement,
                      transformToLiteralValue
                    ], undefined, undefined);
      
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
  });

var serializeActions = [{
    TAG: /* SyncTransform */2,
    _0: (function (input, struct, param) {
        var match = struct.t;
        var fieldNames = match.fieldNames;
        var fields = match.fields;
        var unknown = {};
        var fieldValues = fieldNames.length <= 1 ? [input] : input;
        for(var idx = 0 ,idx_finish = fieldNames.length; idx < idx_finish; ++idx){
          var fieldName = fieldNames[idx];
          var fieldStruct = fields[fieldName];
          var fieldValue = fieldValues[idx];
          var fn = fieldStruct.s;
          if (typeof fn === "number") {
            unknown[fieldName] = fieldValue;
          } else if (fn.TAG === /* Sync */0) {
            try {
              var fieldData = fn._0(fieldValue);
              unknown[fieldName] = fieldData;
            }
            catch (raw_internalError){
              var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
              if (internalError.RE_EXN_ID === Exception) {
                throw {
                      RE_EXN_ID: Exception,
                      _1: prependLocation(internalError._1, fieldName),
                      Error: new Error()
                    };
              }
              throw internalError;
            }
          } else {
            panic("Unreachable");
          }
        }
        return unknown;
      })
  }];

function innerFactory(fieldsArray) {
  var fields = Js_dict.fromArray(fieldsArray);
  var fieldNames = Object.keys(fields);
  var makeParseActions = function (mode) {
    var noopOps = [];
    var syncOps = [];
    var asyncOps = [];
    for(var idx = 0 ,idx_finish = fieldNames.length; idx < idx_finish; ++idx){
      var fieldName = fieldNames[idx];
      var fieldStruct = fields[fieldName];
      var fn = fieldStruct.p[mode];
      if (typeof fn === "number") {
        noopOps.push([
              idx,
              fieldName
            ]);
      } else if (fn.TAG === /* Sync */0) {
        syncOps.push([
              idx,
              fieldName,
              fn._0
            ]);
      } else {
        asyncOps.push([
              idx,
              fieldName,
              fn._0
            ]);
      }
    }
    var withAsyncOps = asyncOps.length > 0;
    var parseActions = [{
        TAG: /* SyncTransform */2,
        _0: (function (input, struct, mode) {
            if (mode === /* Safe */0 && (typeof input === "object" && !Array.isArray(input) && input !== null) === false) {
              raiseUnexpectedTypeError(input, struct);
            }
            var match = struct.t;
            var newArray = [];
            for(var idx = 0 ,idx_finish = syncOps.length; idx < idx_finish; ++idx){
              var match$1 = syncOps[idx];
              var fieldName = match$1[1];
              var fieldData = input[fieldName];
              try {
                var value = match$1[2](fieldData);
                newArray[match$1[0]] = value;
              }
              catch (raw_internalError){
                var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                if (internalError.RE_EXN_ID === Exception) {
                  throw {
                        RE_EXN_ID: Exception,
                        _1: prependLocation(internalError._1, fieldName),
                        Error: new Error()
                      };
                }
                throw internalError;
              }
            }
            for(var idx$1 = 0 ,idx_finish$1 = noopOps.length; idx$1 < idx_finish$1; ++idx$1){
              var match$2 = noopOps[idx$1];
              var fieldData$1 = input[match$2[1]];
              newArray[match$2[0]] = fieldData$1;
            }
            if (match.unknownKeys === /* Strict */0 && mode === /* Safe */0) {
              var excessKey = getMaybeExcessKey(input, fields);
              if (excessKey !== undefined) {
                raise({
                      TAG: /* ExcessField */4,
                      _0: excessKey
                    });
              }
              
            }
            if (withAsyncOps) {
              return {
                      tempArray: newArray,
                      originalInput: input
                    };
            } else if (newArray.length <= 1) {
              return newArray[0];
            } else {
              return newArray;
            }
          })
      }];
    if (withAsyncOps) {
      parseActions.push({
            TAG: /* AsyncTransform */1,
            _0: (function (input, param, param$1) {
                var tempArray = input.tempArray;
                return Promise.all(asyncOps.map(function (param) {
                                  var fieldName = param[1];
                                  var fieldData = input.originalInput[fieldName];
                                  try {
                                    return param[2](fieldData).catch(function (exn) {
                                                return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                                RE_EXN_ID: Exception,
                                                                _1: prependLocation(exn._1, fieldName)
                                                              }) : exn);
                                              });
                                  }
                                  catch (raw_internalError){
                                    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                                    if (internalError.RE_EXN_ID === Exception) {
                                      return $$throw({
                                                  RE_EXN_ID: Exception,
                                                  _1: prependLocation(internalError._1, fieldName)
                                                });
                                    }
                                    throw internalError;
                                  }
                                })).then(function (asyncFieldValues) {
                            asyncFieldValues.forEach(function (fieldValue, idx) {
                                  var match = asyncOps[idx];
                                  tempArray[match[0]] = fieldValue;
                                  
                                });
                            return tempArray;
                          });
              })
          });
    }
    return parseActions;
  };
  return make$1({
              TAG: /* Record */4,
              fields: fields,
              fieldNames: fieldNames,
              unknownKeys: /* Strict */0
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions, undefined, undefined);
}

var factory$2 = callWithArguments(innerFactory);

function strip(struct) {
  var tagged_t = struct.t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return panic("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return make$1({
                TAG: /* Record */4,
                fields: tagged_t.fields,
                fieldNames: tagged_t.fieldNames,
                unknownKeys: /* Strip */1
              }, struct.sp, struct.mp, struct.sa, struct.m, undefined);
  }
}

function strict(struct) {
  var tagged_t = struct.t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return panic("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return make$1({
                TAG: /* Record */4,
                fields: tagged_t.fields,
                fieldNames: tagged_t.fieldNames,
                unknownKeys: /* Strict */0
              }, struct.sp, struct.mp, struct.sa, struct.m, undefined);
  }
}

var actions = [{
    TAG: /* SyncRefine */3,
    _0: (function (input, struct, param) {
        return raiseUnexpectedTypeError(input, struct);
      })
  }];

function factory$3(param) {
  return make$1(/* Never */0, actions, emptyArray, actions, undefined, undefined);
}

function factory$4(param) {
  return make$1(/* Unknown */1, emptyArray, emptyArray, emptyArray, undefined, undefined);
}

var cuidRegex = /^c[^\s-]{8,}$/i;

var uuidRegex = /^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i;

var emailRegex = /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;

var parserRefinement$7 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (typeof input !== "string") {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

function factory$5(param) {
  return make$1(/* String */2, [parserRefinement$7], emptyArray, emptyArray, undefined, undefined);
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

var parserRefinement$8 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (typeof input !== "boolean") {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

function factory$6(param) {
  return make$1(/* Bool */5, [parserRefinement$8], emptyArray, emptyArray, undefined, undefined);
}

var parserRefinement$9 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (!(typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input))) {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

function factory$7(param) {
  return make$1(/* Int */3, [parserRefinement$9], emptyArray, emptyArray, undefined, undefined);
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

var parserRefinement$10 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      if (typeof input === "number" && !Number.isNaN(input)) {
        return ;
      } else {
        return raiseUnexpectedTypeError(input, struct);
      }
    })
};

function factory$8(param) {
  return make$1(/* Float */4, [parserRefinement$10], emptyArray, emptyArray, undefined, undefined);
}

var parserRefinement$11 = {
  TAG: /* SyncRefine */3,
  _0: (function (input, struct, param) {
      var factory = struct.t._0;
      if (!(factoryOf(factory, input) && !Number.isNaN(input.getTime()))) {
        return raiseUnexpectedTypeError(input, struct);
      }
      
    })
};

function factory$9(param) {
  return make$1({
              TAG: /* Instance */10,
              _0: Date
            }, [parserRefinement$11], emptyArray, emptyArray, undefined, undefined);
}

var serializeActions$1 = [{
    TAG: /* SyncTransform */2,
    _0: (function (input, struct, param) {
        if (input === undefined) {
          return null;
        }
        var value = Caml_option.valFromOption(input);
        var innerStruct = struct.t._0;
        var fn = innerStruct.s;
        if (typeof fn === "number") {
          return value;
        } else if (fn.TAG === /* Sync */0) {
          return fn._0(value);
        } else {
          return panic("Unreachable");
        }
      })
  }];

function factory$10(innerStruct) {
  var makeParseActions = function (mode) {
    var fn = innerStruct.p[mode];
    if (typeof fn === "number") {
      return [{
                TAG: /* SyncTransform */2,
                _0: (function (input, param, param$1) {
                    if (input === null) {
                      return ;
                    } else {
                      return Caml_option.some(input);
                    }
                  })
              }];
    }
    if (fn.TAG === /* Sync */0) {
      var fn$1 = fn._0;
      return [{
                TAG: /* SyncTransform */2,
                _0: (function (input, param, param$1) {
                    if (input !== null) {
                      return Caml_option.some(fn$1(input));
                    }
                    
                  })
              }];
    }
    var fn$2 = fn._0;
    return [{
              TAG: /* AsyncTransform */1,
              _0: (function (input, param, param$1) {
                  if (input !== null) {
                    return fn$2(input).then(function (value) {
                                return Caml_option.some(value);
                              });
                  } else {
                    return Promise.resolve(undefined);
                  }
                })
            }];
  };
  return make$1({
              TAG: /* Null */2,
              _0: innerStruct
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions$1, undefined, undefined);
}

var serializeActions$2 = [{
    TAG: /* SyncTransform */2,
    _0: (function (input, struct, param) {
        if (input === undefined) {
          return ;
        }
        var value = Caml_option.valFromOption(input);
        var innerStruct = struct.t._0;
        var fn = innerStruct.s;
        if (typeof fn === "number") {
          return value;
        } else if (fn.TAG === /* Sync */0) {
          return fn._0(value);
        } else {
          return panic("Unreachable");
        }
      })
  }];

function factory$11(innerStruct) {
  var makeParseActions = function (mode) {
    var fn = innerStruct.p[mode];
    if (typeof fn === "number") {
      return emptyArray;
    }
    if (fn.TAG === /* Sync */0) {
      var fn$1 = fn._0;
      return [{
                TAG: /* SyncTransform */2,
                _0: (function (input, param, param$1) {
                    if (input !== undefined) {
                      return Caml_option.some(fn$1(Caml_option.valFromOption(input)));
                    }
                    
                  })
              }];
    }
    var fn$2 = fn._0;
    return [{
              TAG: /* AsyncTransform */1,
              _0: (function (input, param, param$1) {
                  if (input !== undefined) {
                    return fn$2(Caml_option.valFromOption(input)).then(function (value) {
                                return Caml_option.some(value);
                              });
                  } else {
                    return Promise.resolve(undefined);
                  }
                })
            }];
  };
  return make$1({
              TAG: /* Option */1,
              _0: innerStruct
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions$2, undefined, undefined);
}

function factory$12(maybeMessage, innerStruct) {
  var serializeActions = [{
      TAG: /* SyncTransform */2,
      _0: (function (input, param, param$1) {
          if (input === undefined) {
            return undefined;
          }
          var value = Caml_option.valFromOption(input);
          var fn = innerStruct.s;
          if (typeof fn === "number") {
            return value;
          } else if (fn.TAG === /* Sync */0) {
            return fn._0(value);
          } else {
            return panic("Unreachable");
          }
        })
    }];
  var makeParseActions = function (mode) {
    var fn = innerStruct.p[mode];
    if (typeof fn === "number") {
      return emptyArray;
    }
    if (fn.TAG === /* Sync */0) {
      var fn$1 = fn._0;
      return [{
                TAG: /* SyncTransform */2,
                _0: (function (input, param, param$1) {
                    if (input !== undefined) {
                      return Caml_option.some(fn$1(Caml_option.valFromOption(input)));
                    }
                    
                  })
              }];
    }
    var fn$2 = fn._0;
    return [{
              TAG: /* AsyncTransform */1,
              _0: (function (input, param, param$1) {
                  if (input !== undefined) {
                    return fn$2(Caml_option.valFromOption(input)).then(function (value) {
                                return Caml_option.some(value);
                              });
                  } else {
                    return Promise.resolve(undefined);
                  }
                })
            }];
  };
  return make$1({
              TAG: /* Deprecated */8,
              struct: innerStruct,
              maybeMessage: maybeMessage
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions, undefined, undefined);
}

function factory$13(innerStruct) {
  var fn = innerStruct.s;
  var serializeActions;
  if (typeof fn === "number") {
    serializeActions = emptyArray;
  } else if (fn.TAG === /* Sync */0) {
    var fn$1 = fn._0;
    serializeActions = [{
        TAG: /* SyncTransform */2,
        _0: (function (input, param, param$1) {
            var newArray = [];
            for(var idx = 0 ,idx_finish = input.length; idx < idx_finish; ++idx){
              var innerData = input[idx];
              try {
                var value = fn$1(innerData);
                newArray.push(value);
              }
              catch (raw_internalError){
                var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                if (internalError.RE_EXN_ID === Exception) {
                  throw {
                        RE_EXN_ID: Exception,
                        _1: prependLocation(internalError._1, idx.toString()),
                        Error: new Error()
                      };
                }
                throw internalError;
              }
            }
            return newArray;
          })
      }];
  } else {
    serializeActions = panic("Unreachable");
  }
  var makeParseActions = function (mode) {
    var parseActions = [];
    if (mode === /* Safe */0) {
      parseActions.push({
            TAG: /* SyncRefine */3,
            _0: (function (input, struct, param) {
                if (Array.isArray(input) === false) {
                  return raiseUnexpectedTypeError(input, struct);
                }
                
              })
          });
    }
    var fn = innerStruct.p[mode];
    if (typeof fn !== "number") {
      if (fn.TAG === /* Sync */0) {
        var fn$1 = fn._0;
        parseActions.push({
              TAG: /* SyncTransform */2,
              _0: (function (input, param, param$1) {
                  var newArray = [];
                  for(var idx = 0 ,idx_finish = input.length; idx < idx_finish; ++idx){
                    var innerData = input[idx];
                    try {
                      var value = fn$1(innerData);
                      newArray.push(value);
                    }
                    catch (raw_internalError){
                      var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                      if (internalError.RE_EXN_ID === Exception) {
                        throw {
                              RE_EXN_ID: Exception,
                              _1: prependLocation(internalError._1, idx.toString()),
                              Error: new Error()
                            };
                      }
                      throw internalError;
                    }
                  }
                  return newArray;
                })
            });
      } else {
        var fn$2 = fn._0;
        parseActions.push({
              TAG: /* AsyncTransform */1,
              _0: (function (input, param, param$1) {
                  return Promise.all(input.map(function (innerData, idx) {
                                  try {
                                    return fn$2(innerData).catch(function (exn) {
                                                return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                                RE_EXN_ID: Exception,
                                                                _1: prependLocation(exn._1, idx.toString())
                                                              }) : exn);
                                              });
                                  }
                                  catch (raw_internalError){
                                    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                                    if (internalError.RE_EXN_ID === Exception) {
                                      return $$throw({
                                                  RE_EXN_ID: Exception,
                                                  _1: prependLocation(internalError._1, idx.toString())
                                                });
                                    }
                                    throw internalError;
                                  }
                                }));
                })
            });
      }
    }
    return parseActions;
  };
  return make$1({
              TAG: /* Array */3,
              _0: innerStruct
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions, undefined, undefined);
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

function factory$14(innerStruct) {
  var fn = innerStruct.s;
  var serializeActions;
  if (typeof fn === "number") {
    serializeActions = emptyArray;
  } else if (fn.TAG === /* Sync */0) {
    var fn$1 = fn._0;
    serializeActions = [{
        TAG: /* SyncTransform */2,
        _0: (function (input, param, param$1) {
            var newDict = {};
            var keys = Object.keys(input);
            for(var idx = 0 ,idx_finish = keys.length; idx < idx_finish; ++idx){
              var key = keys[idx];
              var innerData = input[key];
              try {
                var value = fn$1(innerData);
                newDict[key] = value;
              }
              catch (raw_internalError){
                var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                if (internalError.RE_EXN_ID === Exception) {
                  throw {
                        RE_EXN_ID: Exception,
                        _1: prependLocation(internalError._1, key),
                        Error: new Error()
                      };
                }
                throw internalError;
              }
            }
            return newDict;
          })
      }];
  } else {
    serializeActions = panic("Unreachable");
  }
  var makeParseActions = function (mode) {
    var parseActions = [];
    if (mode === /* Safe */0) {
      parseActions.push({
            TAG: /* SyncRefine */3,
            _0: (function (input, struct, param) {
                if ((typeof input === "object" && !Array.isArray(input) && input !== null) === false) {
                  return raiseUnexpectedTypeError(input, struct);
                }
                
              })
          });
    }
    var fn = innerStruct.p[mode];
    if (typeof fn !== "number") {
      if (fn.TAG === /* Sync */0) {
        var fn$1 = fn._0;
        parseActions.push({
              TAG: /* SyncTransform */2,
              _0: (function (input, param, param$1) {
                  var newDict = {};
                  var keys = Object.keys(input);
                  for(var idx = 0 ,idx_finish = keys.length; idx < idx_finish; ++idx){
                    var key = keys[idx];
                    var innerData = input[key];
                    try {
                      var value = fn$1(innerData);
                      newDict[key] = value;
                    }
                    catch (raw_internalError){
                      var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                      if (internalError.RE_EXN_ID === Exception) {
                        throw {
                              RE_EXN_ID: Exception,
                              _1: prependLocation(internalError._1, key),
                              Error: new Error()
                            };
                      }
                      throw internalError;
                    }
                  }
                  return newDict;
                })
            });
      } else {
        var fn$2 = fn._0;
        parseActions.push({
              TAG: /* AsyncTransform */1,
              _0: (function (input, param, param$1) {
                  var keys = Object.keys(input);
                  return Promise.all(keys.map(function (key) {
                                    var innerData = input[key];
                                    try {
                                      return fn$2(innerData).catch(function (exn) {
                                                  return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                                  RE_EXN_ID: Exception,
                                                                  _1: prependLocation(exn._1, key)
                                                                }) : exn);
                                                });
                                    }
                                    catch (raw_internalError){
                                      var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                                      if (internalError.RE_EXN_ID === Exception) {
                                        return $$throw({
                                                    RE_EXN_ID: Exception,
                                                    _1: prependLocation(internalError._1, key)
                                                  });
                                      }
                                      throw internalError;
                                    }
                                  })).then(function (values) {
                              var tempDict = {};
                              values.forEach(function (value, idx) {
                                    var key = keys[idx];
                                    tempDict[key] = value;
                                    
                                  });
                              return tempDict;
                            });
                })
            });
      }
    }
    return parseActions;
  };
  return make$1({
              TAG: /* Dict */7,
              _0: innerStruct
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions, undefined, undefined);
}

function factory$15(innerStruct, defaultValue) {
  var serializeActions = [{
      TAG: /* SyncTransform */2,
      _0: (function (input, param, param$1) {
          var value = Caml_option.some(input);
          var fn = innerStruct.s;
          if (typeof fn === "number") {
            return value;
          } else if (fn.TAG === /* Sync */0) {
            return fn._0(value);
          } else {
            return panic("Unreachable");
          }
        })
    }];
  var makeParseActions = function (mode) {
    var fn = innerStruct.p[mode];
    if (typeof fn === "number") {
      return [{
                TAG: /* SyncTransform */2,
                _0: (function (input, param, param$1) {
                    if (input !== undefined) {
                      return Caml_option.valFromOption(input);
                    } else {
                      return defaultValue;
                    }
                  })
              }];
    }
    if (fn.TAG === /* Sync */0) {
      var fn$1 = fn._0;
      return [{
                TAG: /* SyncTransform */2,
                _0: (function (input, param, param$1) {
                    var output = fn$1(input);
                    if (output !== undefined) {
                      return Caml_option.valFromOption(output);
                    } else {
                      return defaultValue;
                    }
                  })
              }];
    }
    var fn$2 = fn._0;
    return [{
              TAG: /* AsyncTransform */1,
              _0: (function (input, param, param$1) {
                  return fn$2(input).then(function (value) {
                              if (value !== undefined) {
                                return Caml_option.valFromOption(value);
                              } else {
                                return defaultValue;
                              }
                            });
                })
            }];
  };
  return make$1({
              TAG: /* Default */9,
              struct: innerStruct,
              value: defaultValue
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions, undefined, undefined);
}

var serializeActions$3 = [{
    TAG: /* SyncTransform */2,
    _0: (function (input, struct, param) {
        var innerStructs = struct.t._0;
        var numberOfStructs = innerStructs.length;
        var inputArray = numberOfStructs === 1 ? [input] : input;
        var newArray = [];
        for(var idx = 0; idx < numberOfStructs; ++idx){
          var innerData = inputArray[idx];
          var innerStruct = innerStructs[idx];
          var fn = innerStruct.s;
          if (typeof fn === "number") {
            newArray.push(innerData);
          } else if (fn.TAG === /* Sync */0) {
            try {
              var value = fn._0(innerData);
              newArray.push(value);
            }
            catch (raw_internalError){
              var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
              if (internalError.RE_EXN_ID === Exception) {
                throw {
                      RE_EXN_ID: Exception,
                      _1: prependLocation(internalError._1, idx.toString()),
                      Error: new Error()
                    };
              }
              throw internalError;
            }
          } else {
            panic("Unreachable");
          }
        }
        return newArray;
      })
  }];

function innerFactory$1(structs) {
  var makeParseActions = function (mode) {
    var numberOfStructs = structs.length;
    var noopOps = [];
    var syncOps = [];
    var asyncOps = [];
    for(var idx = 0 ,idx_finish = structs.length; idx < idx_finish; ++idx){
      var innerStruct = structs[idx];
      var fn = innerStruct.p[mode];
      if (typeof fn === "number") {
        noopOps.push(idx);
      } else if (fn.TAG === /* Sync */0) {
        syncOps.push([
              idx,
              fn._0
            ]);
      } else {
        asyncOps.push([
              idx,
              fn._0
            ]);
      }
    }
    var withAsyncOps = asyncOps.length > 0;
    var parseActions = [{
        TAG: /* SyncTransform */2,
        _0: (function (input, struct, mode) {
            if (mode === /* Safe */0) {
              if (Array.isArray(input)) {
                var numberOfInputItems = input.length;
                if (numberOfStructs !== numberOfInputItems) {
                  raise({
                        TAG: /* TupleSize */3,
                        expected: numberOfStructs,
                        received: numberOfInputItems
                      });
                }
                
              } else {
                raiseUnexpectedTypeError(input, struct);
              }
            }
            var newArray = [];
            for(var idx = 0 ,idx_finish = syncOps.length; idx < idx_finish; ++idx){
              var match = syncOps[idx];
              var originalIdx = match[0];
              var innerData = input[originalIdx];
              try {
                var value = match[1](innerData);
                newArray[originalIdx] = value;
              }
              catch (raw_internalError){
                var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                if (internalError.RE_EXN_ID === Exception) {
                  throw {
                        RE_EXN_ID: Exception,
                        _1: prependLocation(internalError._1, idx.toString()),
                        Error: new Error()
                      };
                }
                throw internalError;
              }
            }
            for(var idx$1 = 0 ,idx_finish$1 = noopOps.length; idx$1 < idx_finish$1; ++idx$1){
              var originalIdx$1 = noopOps[idx$1];
              var innerData$1 = input[originalIdx$1];
              newArray[originalIdx$1] = innerData$1;
            }
            if (withAsyncOps) {
              return {
                      tempArray: newArray,
                      originalInput: input
                    };
            } else if (numberOfStructs !== 0) {
              if (numberOfStructs !== 1) {
                return newArray;
              } else {
                return newArray[0];
              }
            } else {
              return ;
            }
          })
      }];
    if (withAsyncOps) {
      parseActions.push({
            TAG: /* AsyncTransform */1,
            _0: (function (input, param, param$1) {
                var tempArray = input.tempArray;
                return Promise.all(asyncOps.map(function (param) {
                                  var originalIdx = param[0];
                                  var innerData = input.originalInput[originalIdx];
                                  try {
                                    return param[1](innerData).catch(function (exn) {
                                                return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                                RE_EXN_ID: Exception,
                                                                _1: prependLocation(exn._1, originalIdx.toString())
                                                              }) : exn);
                                              });
                                  }
                                  catch (raw_internalError){
                                    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                                    if (internalError.RE_EXN_ID === Exception) {
                                      return $$throw({
                                                  RE_EXN_ID: Exception,
                                                  _1: prependLocation(internalError._1, originalIdx.toString())
                                                });
                                    }
                                    throw internalError;
                                  }
                                })).then(function (values) {
                            values.forEach(function (value, idx) {
                                  var match = asyncOps[idx];
                                  tempArray[match[0]] = value;
                                  
                                });
                            if (tempArray.length <= 1) {
                              return tempArray[0];
                            } else {
                              return tempArray;
                            }
                          });
              })
          });
    }
    return parseActions;
  };
  return make$1({
              TAG: /* Tuple */5,
              _0: structs
            }, makeParseActions(/* Safe */0), makeParseActions(/* Migration */1), serializeActions$3, undefined, undefined);
}

var factory$16 = callWithArguments(innerFactory$1);

var HackyValidValue = /* @__PURE__ */Caml_exceptions.create("S.Union.HackyValidValue");

var serializeActions$4 = [{
    TAG: /* SyncTransform */2,
    _0: (function (input, struct, param) {
        var innerStructs = struct.t._0;
        var idxRef = 0;
        var maybeLastErrorRef;
        var maybeNewValueRef;
        while(idxRef < innerStructs.length && maybeNewValueRef === undefined) {
          var idx = idxRef;
          var innerStruct = innerStructs[idx];
          try {
            var fn = innerStruct.s;
            var newValue;
            newValue = typeof fn === "number" ? input : (
                fn.TAG === /* Sync */0 ? fn._0(input) : panic("Unreachable")
              );
            maybeNewValueRef = Caml_option.some(newValue);
          }
          catch (raw_internalError){
            var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
            if (internalError.RE_EXN_ID === Exception) {
              maybeLastErrorRef = internalError._1;
              idxRef = idxRef + 1;
            } else {
              throw internalError;
            }
          }
        };
        var ok = maybeNewValueRef;
        if (ok !== undefined) {
          return Caml_option.valFromOption(ok);
        }
        var error = maybeLastErrorRef;
        if (error !== undefined) {
          throw {
                RE_EXN_ID: Exception,
                _1: error,
                Error: new Error()
              };
        }
        return undefined;
      })
  }];

function factory$17(structs) {
  if (structs.length < 2) {
    panic("A Union struct factory require at least two structs");
  }
  var noopOps = [];
  var syncOps = [];
  var asyncOps = [];
  for(var idx = 0 ,idx_finish = structs.length; idx < idx_finish; ++idx){
    var innerStruct = structs[idx];
    var fn = innerStruct.p[/* Safe */0];
    if (typeof fn === "number") {
      noopOps.push(undefined);
    } else if (fn.TAG === /* Sync */0) {
      syncOps.push(fn._0);
    } else {
      asyncOps.push(fn._0);
    }
  }
  var withAsyncOps = asyncOps.length > 0;
  var parseActions;
  if (noopOps.length > 0) {
    parseActions = emptyArray;
  } else {
    var parseActions$1 = [{
        TAG: /* SyncTransform */2,
        _0: (function (input, param, param$1) {
            var idxRef = 0;
            var errorsRef = [];
            var maybeNewValueRef;
            while(idxRef < syncOps.length && maybeNewValueRef === undefined) {
              var idx = idxRef;
              var fn = syncOps[idx];
              try {
                var newValue = fn(input);
                maybeNewValueRef = Caml_option.some(newValue);
              }
              catch (raw_internalError){
                var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                if (internalError.RE_EXN_ID === Exception) {
                  errorsRef.push(internalError._1);
                  idxRef = idxRef + 1;
                } else {
                  throw internalError;
                }
              }
            };
            var match = maybeNewValueRef;
            if (match !== undefined) {
              if (withAsyncOps) {
                return {
                        maybeSyncValue: match,
                        syncErrors: errorsRef,
                        originalInput: input
                      };
              } else {
                return Caml_option.valFromOption(match);
              }
            } else if (withAsyncOps) {
              return {
                      maybeSyncValue: match,
                      syncErrors: errorsRef,
                      originalInput: input
                    };
            } else {
              return raise({
                          TAG: /* InvalidUnion */5,
                          _0: errorsRef.map(toParseError)
                        });
            }
          })
      }];
    if (withAsyncOps) {
      parseActions$1.push({
            TAG: /* AsyncTransform */1,
            _0: (function (input, param, param$1) {
                var syncValue = input.maybeSyncValue;
                if (syncValue !== undefined) {
                  return Promise.resolve(Caml_option.valFromOption(syncValue));
                } else {
                  return Promise.all(asyncOps.map(function (fn) {
                                    try {
                                      return fn(input.originalInput).then((function (value) {
                                                    throw {
                                                          RE_EXN_ID: HackyValidValue,
                                                          _1: value,
                                                          Error: new Error()
                                                        };
                                                  }), (function (exn) {
                                                    if (exn.RE_EXN_ID === Exception) {
                                                      return exn._1;
                                                    } else {
                                                      return $$throw(exn);
                                                    }
                                                  }));
                                    }
                                    catch (raw_internalError){
                                      var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                                      if (internalError.RE_EXN_ID === Exception) {
                                        return Promise.resolve(internalError._1);
                                      }
                                      throw internalError;
                                    }
                                  })).then((function (asyncErrors) {
                                return raise({
                                            TAG: /* InvalidUnion */5,
                                            _0: input.syncErrors.concat(asyncErrors).map(toParseError)
                                          });
                              }), (function (exn) {
                                if (exn.RE_EXN_ID === HackyValidValue) {
                                  return exn._1;
                                } else {
                                  return $$throw(exn);
                                }
                              }));
                }
              })
          });
    }
    parseActions = parseActions$1;
  }
  return make$1({
              TAG: /* Union */6,
              _0: structs
            }, parseActions, parseActions, serializeActions$4, undefined, undefined);
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
                      _0: make(Belt_Option.getWithDefault(obj._1.message, "Failed to parse JSON"))
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
              }), (function (transformed, param) {
                var result = serializeWith(transformed, innerStruct);
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
    return panic(toString(result._0));
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
  make: make,
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
            sp: struct.sp,
            mp: struct.mp,
            sa: struct.sa,
            s: struct.s,
            p: struct.p,
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
exports.asyncRefine = asyncRefine;
exports.parseWith = parseWith;
exports.parseAsyncWith = parseAsyncWith;
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
