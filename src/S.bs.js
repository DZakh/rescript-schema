'use strict';

var Js_exn = require("rescript/lib/js/js_exn.js");
var Js_dict = require("rescript/lib/js/js_dict.js");
var Js_types = require("rescript/lib/js/js_types.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_exceptions = require("rescript/lib/js/caml_exceptions.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");

function parentOf(class_, data) {
  return (data instanceof class_);
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

function toParseError(internalError) {
  return {
          operation: /* Parsing */1,
          code: internalError.code,
          path: internalError.path
        };
}

function toSerializeError(internalError) {
  return {
          operation: /* Serializing */0,
          code: internalError.code,
          path: internalError.path
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

function raiseCustom(error) {
  throw {
        RE_EXN_ID: Exception,
        _1: error,
        Error: new Error()
      };
}

function raise$2(message) {
  throw {
        RE_EXN_ID: Exception,
        _1: {
          code: {
            TAG: /* OperationFailed */0,
            _0: message
          },
          path: []
        },
        Error: new Error()
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
          return "Expected Tuple with " + reason.expected.toString() + " items, received " + reason.received.toString() + "";
      case /* ExcessField */4 :
          return "Encountered disallowed excess key \"" + reason._0 + "\" on an object. Use Deprecated to ignore a specific field, or S.Record.strip to ignore excess keys completely";
      case /* InvalidUnion */5 :
          var lineBreak = "\n" + " ".repeat((nestedLevel << 1)) + "";
          var array = reason._0.map(function (error) {
                var reason = toReason(nestedLevel + 1, error);
                var nonEmptyPath = error.path;
                var $$location = nonEmptyPath.length !== 0 ? "Failed at " + formatPath(nonEmptyPath) + ". " : "";
                return "- " + $$location + "" + reason + "";
              });
          var reasons = Array.from(new Set(array));
          return "Invalid union with following errors" + lineBreak + "" + reasons.join(lineBreak) + "";
      
    }
  }
  return "Expected " + reason.expected + ", received " + reason.received + "";
}

function toString(error) {
  var match = error.operation;
  var operation = match ? "parsing" : "serializing";
  var reason = toReason(undefined, error);
  var pathText = formatPath(error.path);
  return "[ReScript Struct] Failed " + operation + " at " + pathText + ". Reason: " + reason + "";
}

function classify(struct) {
  return struct.t;
}

function isAsyncParse(struct) {
  var match = struct.p;
  if (typeof match === "number" || match.TAG === /* SyncOperation */0) {
    return false;
  } else {
    return true;
  }
}

function isAsyncSerialize(struct) {
  var match = struct.s;
  if (typeof match === "number" || match.TAG === /* SyncOperation */0) {
    return false;
  } else {
    return true;
  }
}

function raiseUnexpectedTypeError(input, struct) {
  var number = Js_types.classify(input);
  var tmp;
  if (typeof number === "number") {
    switch (number) {
      case /* JSFalse */0 :
      case /* JSTrue */1 :
          tmp = "Bool";
          break;
      case /* JSNull */2 :
          tmp = "Null";
          break;
      case /* JSUndefined */3 :
          tmp = "Option";
          break;
      
    }
  } else {
    switch (number.TAG | 0) {
      case /* JSNumber */0 :
          tmp = Number.isNaN(number._0) ? "NaN Literal (NaN)" : "Float";
          break;
      case /* JSString */1 :
          tmp = "String";
          break;
      case /* JSFunction */2 :
          tmp = "Function";
          break;
      case /* JSObject */3 :
          tmp = "Object";
          break;
      case /* JSSymbol */4 :
          tmp = "Symbol";
          break;
      case /* JSBigInt */5 :
          tmp = "BigInt";
          break;
      
    }
  }
  return raise({
              TAG: /* UnexpectedType */1,
              expected: struct.n,
              received: tmp
            });
}

function makeOperation(actionFactories, struct) {
  if (actionFactories.length === 0) {
    return /* NoopOperation */0;
  }
  var lastActionIdx = actionFactories.length - 1 | 0;
  var lastSyncActionIdxRef = {
    contents: lastActionIdx
  };
  var actions = [];
  for(var idx = 0 ,idx_finish = lastSyncActionIdxRef.contents; idx <= idx_finish; ++idx){
    var actionFactory = actionFactories[idx];
    var action = actionFactory(struct);
    actions.push(action);
    if (lastSyncActionIdxRef.contents === lastActionIdx && action.TAG !== /* Sync */0) {
      lastSyncActionIdxRef.contents = idx - 1 | 0;
    }
    
  }
  var syncOperation = lastSyncActionIdxRef.contents === 0 ? actions[0]._0 : (function (input) {
        var tempOuputRef = input;
        for(var idx = 0 ,idx_finish = lastSyncActionIdxRef.contents; idx <= idx_finish; ++idx){
          var action = actions[idx];
          var newValue = action._0(tempOuputRef);
          tempOuputRef = newValue;
        }
        return tempOuputRef;
      });
  if (lastActionIdx === lastSyncActionIdxRef.contents) {
    return {
            TAG: /* SyncOperation */0,
            _0: syncOperation
          };
  } else {
    return {
            TAG: /* AsyncOperation */1,
            _0: (function (input) {
                var match = lastSyncActionIdxRef.contents;
                var syncOutput = match !== -1 ? syncOperation(input) : input;
                return function () {
                  var tempOuputRef = Promise.resolve(syncOutput);
                  for(var idx = lastSyncActionIdxRef.contents + 1 | 0; idx <= lastActionIdx; ++idx){
                    var action = actions[idx];
                    tempOuputRef = tempOuputRef.then((function(action){
                        return function (tempOutput) {
                          if (action.TAG === /* Sync */0) {
                            return Promise.resolve(action._0(tempOutput));
                          } else {
                            return action._0(tempOutput);
                          }
                        }
                        }(action)));
                  }
                  return tempOuputRef;
                };
              })
          };
  }
}

function make(name, tagged_t, parseActionFactories, serializeActionFactories, maybeMetadata, param) {
  var struct_s = undefined;
  var struct_p = undefined;
  var struct = {
    n: name,
    t: tagged_t,
    pf: parseActionFactories,
    sf: serializeActionFactories,
    s: struct_s,
    p: struct_p,
    m: maybeMetadata
  };
  return {
          n: name,
          t: tagged_t,
          pf: parseActionFactories,
          sf: serializeActionFactories,
          s: makeOperation(serializeActionFactories, struct),
          p: makeOperation(parseActionFactories, struct),
          m: maybeMetadata
        };
}

function parseWith(any, struct) {
  try {
    var fn = struct.p;
    if (typeof fn === "number") {
      return {
              TAG: /* Ok */0,
              _0: any
            };
    } else if (fn.TAG === /* SyncOperation */0) {
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

function parseAsyncWith(any, struct) {
  try {
    var fn = struct.p;
    if (typeof fn === "number") {
      return Promise.resolve({
                  TAG: /* Ok */0,
                  _0: any
                });
    } else if (fn.TAG === /* SyncOperation */0) {
      return Promise.resolve({
                  TAG: /* Ok */0,
                  _0: fn._0(any)
                });
    } else {
      return fn._0(any)().then(function (value) {
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
                });
    }
  }
  catch (raw_internalError){
    var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
    if (internalError.RE_EXN_ID === Exception) {
      return Promise.resolve({
                  TAG: /* Error */1,
                  _0: toParseError(internalError._1)
                });
    }
    throw internalError;
  }
}

function parseAsyncInStepsWith(any, struct) {
  try {
    var fn = struct.p;
    var tmp;
    if (typeof fn === "number") {
      tmp = (function (param) {
          return Promise.resolve({
                      TAG: /* Ok */0,
                      _0: any
                    });
        });
    } else if (fn.TAG === /* SyncOperation */0) {
      var syncValue = fn._0(any);
      tmp = (function (param) {
          return Promise.resolve({
                      TAG: /* Ok */0,
                      _0: syncValue
                    });
        });
    } else {
      var asyncFn = fn._0(any);
      tmp = (function (param) {
          return asyncFn().then(function (value) {
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
                    });
        });
    }
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
        fn.TAG === /* SyncOperation */0 ? fn._0(value) : panic("Unreachable")
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

var action = {
  TAG: /* Sync */0,
  _0: (function (param) {
      return raise(/* MissingParser */0);
    })
};

function missingParser(param) {
  return action;
}

var action$1 = {
  TAG: /* Sync */0,
  _0: (function (param) {
      return raise(/* MissingSerializer */1);
    })
};

function missingSerializer(param) {
  return action$1;
}

function refine(struct, maybeRefineParser, maybeRefineSerializer, param) {
  if (maybeRefineParser === undefined && maybeRefineSerializer === undefined) {
    panic$1("struct factory Refine");
  }
  var fn = function (refineParser) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          refineParser(input);
          return input;
        })
    };
    return function (param) {
      return action;
    };
  };
  var maybeParseActionFactory = maybeRefineParser !== undefined ? Caml_option.some(fn(Caml_option.valFromOption(maybeRefineParser))) : undefined;
  var tmp;
  if (maybeRefineSerializer !== undefined) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          maybeRefineSerializer(input);
          return input;
        })
    };
    tmp = [(function (param) {
            return action;
          })].concat(struct.sf);
  } else {
    tmp = struct.sf;
  }
  return make(struct.n, struct.t, maybeParseActionFactory !== undefined ? struct.pf.concat([maybeParseActionFactory]) : struct.pf, tmp, struct.m, undefined);
}

function asyncRefine(struct, parser, param) {
  var action = {
    TAG: /* Async */1,
    _0: (function (input) {
        return parser(input).then(function (param) {
                    return input;
                  });
      })
  };
  return make(struct.n, struct.t, struct.pf.concat([(function (param) {
                      return action;
                    })]), struct.sf, struct.m, undefined);
}

function transform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    panic$1("struct factory Transform");
  }
  var tmp;
  if (maybeTransformationParser !== undefined) {
    var action = {
      TAG: /* Sync */0,
      _0: maybeTransformationParser
    };
    tmp = (function (param) {
        return action;
      });
  } else {
    tmp = missingParser;
  }
  var tmp$1;
  if (maybeTransformationSerializer !== undefined) {
    var action$1 = {
      TAG: /* Sync */0,
      _0: maybeTransformationSerializer
    };
    tmp$1 = (function (param) {
        return action$1;
      });
  } else {
    tmp$1 = missingSerializer;
  }
  return make(struct.n, struct.t, struct.pf.concat([tmp]), [tmp$1].concat(struct.sf), struct.m, undefined);
}

function advancedTransform(struct, maybeTransformationParser, maybeTransformationSerializer, param) {
  if (maybeTransformationParser === undefined && maybeTransformationSerializer === undefined) {
    panic$1("struct factory Transform");
  }
  return make(struct.n, struct.t, struct.pf.concat([maybeTransformationParser !== undefined ? maybeTransformationParser : missingParser]), [maybeTransformationSerializer !== undefined ? maybeTransformationSerializer : missingSerializer].concat(struct.sf), struct.m, undefined);
}

function custom(name, maybeCustomParser, maybeCustomSerializer, param) {
  if (maybeCustomParser === undefined && maybeCustomSerializer === undefined) {
    panic$1("Custom struct factory");
  }
  var tmp;
  if (maybeCustomSerializer !== undefined) {
    var action = {
      TAG: /* Sync */0,
      _0: Caml_option.valFromOption(maybeCustomSerializer)
    };
    tmp = (function (param) {
        return action;
      });
  } else {
    tmp = missingSerializer;
  }
  return make(name, /* Unknown */1, [maybeCustomParser !== undefined ? (function (param) {
                    return {
                            TAG: /* Sync */0,
                            _0: (function (input) {
                                return maybeCustomParser(input);
                              })
                          };
                  }) : missingParser], [tmp], undefined, undefined);
}

function factory(innerLiteral, variant) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  var makeParseActionFactories = function (literalValue, test) {
    return [(function (struct) {
                return {
                        TAG: /* Sync */0,
                        _0: (function (input) {
                            if (test(input)) {
                              if (literalValue === input) {
                                return variant;
                              } else {
                                return raise$1(literalValue, input);
                              }
                            } else {
                              return raiseUnexpectedTypeError(input, struct);
                            }
                          })
                      };
              })];
  };
  var makeSerializeActionFactories = function (output) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          if (input === variant) {
            return output;
          } else {
            return raise$1(variant, input);
          }
        })
    };
    return [(function (param) {
                return action;
              })];
  };
  if (typeof innerLiteral === "number") {
    switch (innerLiteral) {
      case /* EmptyNull */0 :
          return make("EmptyNull Literal (null)", tagged_t, [(function (struct) {
                          return {
                                  TAG: /* Sync */0,
                                  _0: (function (input) {
                                      if (input === null) {
                                        return variant;
                                      } else {
                                        return raiseUnexpectedTypeError(input, struct);
                                      }
                                    })
                                };
                        })], makeSerializeActionFactories(null), undefined, undefined);
      case /* EmptyOption */1 :
          return make("EmptyOption Literal (undefined)", tagged_t, [(function (struct) {
                          return {
                                  TAG: /* Sync */0,
                                  _0: (function (input) {
                                      if (input === undefined) {
                                        return variant;
                                      } else {
                                        return raiseUnexpectedTypeError(input, struct);
                                      }
                                    })
                                };
                        })], makeSerializeActionFactories(undefined), undefined, undefined);
      case /* NaN */2 :
          return make("NaN Literal (NaN)", tagged_t, [(function (struct) {
                          return {
                                  TAG: /* Sync */0,
                                  _0: (function (input) {
                                      if (Number.isNaN(input)) {
                                        return variant;
                                      } else {
                                        return raiseUnexpectedTypeError(input, struct);
                                      }
                                    })
                                };
                        })], makeSerializeActionFactories(NaN), undefined, undefined);
      
    }
  } else {
    switch (innerLiteral.TAG | 0) {
      case /* String */0 :
          var string = innerLiteral._0;
          return make("String Literal (\"" + string + "\")", tagged_t, makeParseActionFactories(string, (function (input) {
                            return typeof input === "string";
                          })), makeSerializeActionFactories(string), undefined, undefined);
      case /* Int */1 :
          var $$int = innerLiteral._0;
          return make("Int Literal (" + $$int.toString() + ")", tagged_t, makeParseActionFactories($$int, (function (input) {
                            if (typeof input === "number" && input < 2147483648 && input > -2147483649) {
                              return input === Math.trunc(input);
                            } else {
                              return false;
                            }
                          })), makeSerializeActionFactories($$int), undefined, undefined);
      case /* Float */2 :
          var $$float = innerLiteral._0;
          return make("Float Literal (" + $$float.toString() + ")", tagged_t, makeParseActionFactories($$float, (function (input) {
                            return typeof input === "number";
                          })), makeSerializeActionFactories($$float), undefined, undefined);
      case /* Bool */3 :
          var bool = innerLiteral._0;
          return make("Bool Literal (" + bool + ")", tagged_t, makeParseActionFactories(bool, (function (input) {
                            return typeof input === "boolean";
                          })), makeSerializeActionFactories(bool), undefined, undefined);
      
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

function innerFactory(fieldsArray) {
  var fields = Js_dict.fromArray(fieldsArray);
  var fieldNames = Object.keys(fields);
  var noopOps = [];
  var syncOps = [];
  var asyncOps = [];
  for(var idx = 0 ,idx_finish = fieldNames.length; idx < idx_finish; ++idx){
    var fieldName = fieldNames[idx];
    var fieldStruct = fields[fieldName];
    var fn = fieldStruct.p;
    if (typeof fn === "number") {
      noopOps.push([
            idx,
            fieldName
          ]);
    } else if (fn.TAG === /* SyncOperation */0) {
      syncOps.push([
            idx,
            fieldName,
            fn._0
          ]);
    } else {
      syncOps.push([
            idx,
            fieldName,
            fn._0
          ]);
      asyncOps.push([
            idx,
            fieldName
          ]);
    }
  }
  var withAsyncOps = asyncOps.length > 0;
  var parseActionFactories = [(function (struct) {
        return {
                TAG: /* Sync */0,
                _0: (function (input) {
                    if ((typeof input === "object" && !Array.isArray(input) && input !== null) === false) {
                      raiseUnexpectedTypeError(input, struct);
                    }
                    var newArray = [];
                    for(var idx = 0 ,idx_finish = syncOps.length; idx < idx_finish; ++idx){
                      var match = syncOps[idx];
                      var fieldName = match[1];
                      var fieldData = input[fieldName];
                      try {
                        var value = match[2](fieldData);
                        newArray[match[0]] = value;
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
                      var match$1 = noopOps[idx$1];
                      var fieldData$1 = input[match$1[1]];
                      newArray[match$1[0]] = fieldData$1;
                    }
                    var match$2 = struct.t;
                    if (match$2.unknownKeys === /* Strict */0) {
                      var excessKey = getMaybeExcessKey(input, fields);
                      if (excessKey !== undefined) {
                        raise({
                              TAG: /* ExcessField */4,
                              _0: excessKey
                            });
                      }
                      
                    }
                    if (withAsyncOps || newArray.length > 1) {
                      return newArray;
                    } else {
                      return newArray[0];
                    }
                  })
              };
      })];
  if (withAsyncOps) {
    var action = {
      TAG: /* Async */1,
      _0: (function (tempArray) {
          return Promise.all(asyncOps.map(function (param) {
                            var fieldName = param[1];
                            return tempArray[param[0]]().catch(function (exn) {
                                        return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                        RE_EXN_ID: Exception,
                                                        _1: prependLocation(exn._1, fieldName)
                                                      }) : exn);
                                      });
                          })).then(function (asyncFieldValues) {
                      asyncFieldValues.forEach(function (fieldValue, idx) {
                            var match = asyncOps[idx];
                            tempArray[match[0]] = fieldValue;
                          });
                      return tempArray;
                    });
        })
    };
    parseActionFactories.push(function (param) {
          return action;
        });
  }
  return make("Record", {
              TAG: /* Record */4,
              fields: fields,
              fieldNames: fieldNames,
              unknownKeys: /* Strip */1
            }, parseActionFactories, [(function (param) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              var unknown = {};
                              var fieldValues = fieldNames.length <= 1 ? [input] : input;
                              for(var idx = 0 ,idx_finish = fieldNames.length; idx < idx_finish; ++idx){
                                var fieldName = fieldNames[idx];
                                var fieldStruct = fields[fieldName];
                                var fieldValue = fieldValues[idx];
                                var fn = fieldStruct.s;
                                if (typeof fn === "number") {
                                  unknown[fieldName] = fieldValue;
                                } else if (fn.TAG === /* SyncOperation */0) {
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
                        };
                })], undefined, undefined);
}

var factory$2 = callWithArguments(innerFactory);

function strip(struct) {
  var tagged_t = struct.t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return panic("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return make(struct.n, {
                TAG: /* Record */4,
                fields: tagged_t.fields,
                fieldNames: tagged_t.fieldNames,
                unknownKeys: /* Strip */1
              }, struct.pf, struct.sf, struct.m, undefined);
  }
}

function strict(struct) {
  var tagged_t = struct.t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return panic("Can't set up unknown keys strategy. The struct is not Record");
  } else {
    return make(struct.n, {
                TAG: /* Record */4,
                fields: tagged_t.fields,
                fieldNames: tagged_t.fieldNames,
                unknownKeys: /* Strict */0
              }, struct.pf, struct.sf, struct.m, undefined);
  }
}

function factory$3(param) {
  var actionFactories = [(function (struct) {
        return {
                TAG: /* Sync */0,
                _0: (function (input) {
                    return raiseUnexpectedTypeError(input, struct);
                  })
              };
      })];
  return make("Never", /* Never */0, actionFactories, actionFactories, undefined, undefined);
}

function factory$4(param) {
  return make("Unknown", /* Unknown */1, emptyArray, emptyArray, undefined, undefined);
}

var cuidRegex = /^c[^\s-]{8,}$/i;

var uuidRegex = /^([a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[a-f0-9]{4}-[a-f0-9]{12}|00000000-0000-0000-0000-000000000000)$/i;

var emailRegex = /^(([^<>()[\]\.,;:\s@\"]+(\.[^<>()[\]\.,;:\s@\"]+)*)|(\".+\"))@(([^<>()[\]\.,;:\s@\"]+\.)+[^<>()[\]\.,;:\s@\"]{2,})$/i;

function factory$5(param) {
  return make("String", /* String */2, [(function (struct) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (typeof input === "string") {
                                return input;
                              } else {
                                return raiseUnexpectedTypeError(input, struct);
                              }
                            })
                        };
                })], emptyArray, undefined, undefined);
}

function min(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length < length) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "String must be " + length.toString() + " or more characters long"));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function max(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length > length) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "String must be " + length.toString() + " or fewer characters long"));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function length(struct, maybeMessage, length$1) {
  var refiner = function (value) {
    if (value.length !== length$1) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "String must be exactly " + length$1.toString() + " characters long"));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function email(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid email address";
  var refiner = function (value) {
    if (!emailRegex.test(value)) {
      return raise$2(message);
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function uuid(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid UUID";
  var refiner = function (value) {
    if (!uuidRegex.test(value)) {
      return raise$2(message);
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function cuid(struct, messageOpt, param) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid CUID";
  var refiner = function (value) {
    if (!cuidRegex.test(value)) {
      return raise$2(message);
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
    if (!tmp) {
      return raise$2(message);
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function pattern(struct, messageOpt, re) {
  var message = messageOpt !== undefined ? messageOpt : "Invalid";
  var refiner = function (value) {
    re.lastIndex = 0;
    if (!re.test(value)) {
      return raise$2(message);
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function trimmed(struct, param) {
  var transformer = function (prim) {
    return prim.trim();
  };
  return transform(struct, transformer, transformer, undefined);
}

function factory$6(param) {
  return make("Bool", /* Bool */5, [(function (struct) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (typeof input === "boolean") {
                                return input;
                              } else {
                                return raiseUnexpectedTypeError(input, struct);
                              }
                            })
                        };
                })], emptyArray, undefined, undefined);
}

function factory$7(param) {
  return make("Int", /* Int */3, [(function (struct) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
                                return input;
                              } else {
                                return raiseUnexpectedTypeError(input, struct);
                              }
                            })
                        };
                })], emptyArray, undefined, undefined);
}

function min$1(struct, maybeMessage, thanValue) {
  var refiner = function (value) {
    if (value < thanValue) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "Number must be greater than or equal to " + thanValue.toString() + ""));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function max$1(struct, maybeMessage, thanValue) {
  var refiner = function (value) {
    if (value > thanValue) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "Number must be lower than or equal to " + thanValue.toString() + ""));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function factory$8(param) {
  return make("Float", /* Float */4, [(function (struct) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (typeof input === "number" && !Number.isNaN(input)) {
                                return input;
                              } else {
                                return raiseUnexpectedTypeError(input, struct);
                              }
                            })
                        };
                })], emptyArray, undefined, undefined);
}

function factory$9(param) {
  var class_ = Date;
  return make("Instance (Date)", {
              TAG: /* Instance */10,
              _0: class_
            }, [(function (struct) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (parentOf(class_, input) && !Number.isNaN(input.getTime())) {
                                return input;
                              } else {
                                return raiseUnexpectedTypeError(input, struct);
                              }
                            })
                        };
                })], emptyArray, undefined, undefined);
}

function factory$10(innerStruct) {
  var makeSyncParseAction = function (fn) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          if (input !== null) {
            return Caml_option.some(fn(input));
          }
          
        })
    };
    return function (param) {
      return action;
    };
  };
  var fn = innerStruct.p;
  var tmp;
  if (typeof fn === "number") {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          if (input === null) {
            return ;
          } else {
            return Caml_option.some(input);
          }
        })
    };
    tmp = [(function (param) {
          return action;
        })];
  } else if (fn.TAG === /* SyncOperation */0) {
    tmp = [makeSyncParseAction(fn._0)];
  } else {
    var action$1 = {
      TAG: /* Async */1,
      _0: (function (input) {
          if (input !== undefined) {
            return input().then(function (value) {
                        return Caml_option.some(value);
                      });
          } else {
            return Promise.resolve(undefined);
          }
        })
    };
    tmp = [
      makeSyncParseAction(fn._0),
      (function (param) {
          return action$1;
        })
    ];
  }
  return make("Null", {
              TAG: /* Null */2,
              _0: innerStruct
            }, tmp, [(function (param) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (input === undefined) {
                                return null;
                              }
                              var value = Caml_option.valFromOption(input);
                              var fn = innerStruct.s;
                              if (typeof fn === "number") {
                                return value;
                              } else if (fn.TAG === /* SyncOperation */0) {
                                return fn._0(value);
                              } else {
                                return panic("Unreachable");
                              }
                            })
                        };
                })], undefined, undefined);
}

function factory$11(innerStruct) {
  var makeSyncParseAction = function (fn) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          if (input !== undefined) {
            return Caml_option.some(fn(Caml_option.valFromOption(input)));
          }
          
        })
    };
    return function (param) {
      return action;
    };
  };
  var fn = innerStruct.p;
  var tmp;
  if (typeof fn === "number") {
    tmp = emptyArray;
  } else if (fn.TAG === /* SyncOperation */0) {
    tmp = [makeSyncParseAction(fn._0)];
  } else {
    var action = {
      TAG: /* Async */1,
      _0: (function (input) {
          if (input !== undefined) {
            return input().then(function (value) {
                        return Caml_option.some(value);
                      });
          } else {
            return Promise.resolve(undefined);
          }
        })
    };
    tmp = [
      makeSyncParseAction(fn._0),
      (function (param) {
          return action;
        })
    ];
  }
  return make("Option", {
              TAG: /* Option */1,
              _0: innerStruct
            }, tmp, [(function (param) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              if (input === undefined) {
                                return ;
                              }
                              var value = Caml_option.valFromOption(input);
                              var fn = innerStruct.s;
                              if (typeof fn === "number") {
                                return value;
                              } else if (fn.TAG === /* SyncOperation */0) {
                                return fn._0(value);
                              } else {
                                return panic("Unreachable");
                              }
                            })
                        };
                })], undefined, undefined);
}

function factory$12(maybeMessage, innerStruct) {
  var makeSyncParseAction = function (fn) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          if (input !== undefined) {
            return Caml_option.some(fn(Caml_option.valFromOption(input)));
          }
          
        })
    };
    return function (param) {
      return action;
    };
  };
  var fn = innerStruct.p;
  var tmp;
  if (typeof fn === "number") {
    tmp = emptyArray;
  } else if (fn.TAG === /* SyncOperation */0) {
    tmp = [makeSyncParseAction(fn._0)];
  } else {
    var action = {
      TAG: /* Async */1,
      _0: (function (input) {
          if (input !== undefined) {
            return input().then(function (value) {
                        return Caml_option.some(value);
                      });
          } else {
            return Promise.resolve(undefined);
          }
        })
    };
    tmp = [
      makeSyncParseAction(fn._0),
      (function (param) {
          return action;
        })
    ];
  }
  var action$1 = {
    TAG: /* Sync */0,
    _0: (function (input) {
        if (input === undefined) {
          return undefined;
        }
        var value = Caml_option.valFromOption(input);
        var fn = innerStruct.s;
        if (typeof fn === "number") {
          return value;
        } else if (fn.TAG === /* SyncOperation */0) {
          return fn._0(value);
        } else {
          return panic("Unreachable");
        }
      })
  };
  return make("Deprecated", {
              TAG: /* Deprecated */8,
              struct: innerStruct,
              maybeMessage: maybeMessage
            }, tmp, [(function (param) {
                  return action$1;
                })], undefined, undefined);
}

function factory$13(innerStruct) {
  var makeSyncParseAction = function (fn) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          var newArray = [];
          for(var idx = 0 ,idx_finish = input.length; idx < idx_finish; ++idx){
            var innerData = input[idx];
            try {
              var value = fn(innerData);
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
    };
    return function (param) {
      return action;
    };
  };
  var parseActionFactories = [(function (struct) {
        return {
                TAG: /* Sync */0,
                _0: (function (input) {
                    if (Array.isArray(input) === false) {
                      return raiseUnexpectedTypeError(input, struct);
                    } else {
                      return input;
                    }
                  })
              };
      })];
  var fn = innerStruct.p;
  if (typeof fn !== "number") {
    parseActionFactories.push(makeSyncParseAction(fn._0));
    if (fn.TAG !== /* SyncOperation */0) {
      var action = {
        TAG: /* Async */1,
        _0: (function (input) {
            return Promise.all(input.map(function (asyncFn, idx) {
                            return asyncFn().catch(function (exn) {
                                        return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                        RE_EXN_ID: Exception,
                                                        _1: prependLocation(exn._1, idx.toString())
                                                      }) : exn);
                                      });
                          }));
          })
      };
      parseActionFactories.push(function (param) {
            return action;
          });
    }
    
  }
  var fn$1 = innerStruct.s;
  var tmp;
  if (typeof fn$1 === "number") {
    tmp = emptyArray;
  } else if (fn$1.TAG === /* SyncOperation */0) {
    var fn$2 = fn$1._0;
    var action$1 = {
      TAG: /* Sync */0,
      _0: (function (input) {
          var newArray = [];
          for(var idx = 0 ,idx_finish = input.length; idx < idx_finish; ++idx){
            var innerData = input[idx];
            try {
              var value = fn$2(innerData);
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
    };
    tmp = [(function (param) {
          return action$1;
        })];
  } else {
    tmp = panic("Unreachable");
  }
  return make("Array", {
              TAG: /* Array */3,
              _0: innerStruct
            }, parseActionFactories, tmp, undefined, undefined);
}

function min$2(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length < length) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "Array must be " + length.toString() + " or more items long"));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function max$2(struct, maybeMessage, length) {
  var refiner = function (value) {
    if (value.length > length) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "Array must be " + length.toString() + " or fewer items long"));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function length$1(struct, maybeMessage, length$2) {
  var refiner = function (value) {
    if (value.length !== length$2) {
      return raise$2(Belt_Option.getWithDefault(maybeMessage, "Array must be exactly " + length$2.toString() + " items long"));
    }
    
  };
  return refine(struct, refiner, refiner, undefined);
}

function factory$14(innerStruct) {
  var makeSyncParseAction = function (fn) {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          var newDict = {};
          var keys = Object.keys(input);
          for(var idx = 0 ,idx_finish = keys.length; idx < idx_finish; ++idx){
            var key = keys[idx];
            var innerData = input[key];
            try {
              var value = fn(innerData);
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
    };
    return function (param) {
      return action;
    };
  };
  var parseActionFactories = [(function (struct) {
        return {
                TAG: /* Sync */0,
                _0: (function (input) {
                    if ((typeof input === "object" && !Array.isArray(input) && input !== null) === false) {
                      return raiseUnexpectedTypeError(input, struct);
                    } else {
                      return input;
                    }
                  })
              };
      })];
  var fn = innerStruct.p;
  if (typeof fn !== "number") {
    parseActionFactories.push(makeSyncParseAction(fn._0));
    if (fn.TAG !== /* SyncOperation */0) {
      var action = {
        TAG: /* Async */1,
        _0: (function (input) {
            var keys = Object.keys(input);
            return Promise.all(keys.map(function (key) {
                              var asyncFn = input[key];
                              try {
                                return asyncFn().catch(function (exn) {
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
      };
      parseActionFactories.push(function (param) {
            return action;
          });
    }
    
  }
  var fn$1 = innerStruct.s;
  var tmp;
  if (typeof fn$1 === "number") {
    tmp = emptyArray;
  } else if (fn$1.TAG === /* SyncOperation */0) {
    var fn$2 = fn$1._0;
    var action$1 = {
      TAG: /* Sync */0,
      _0: (function (input) {
          var newDict = {};
          var keys = Object.keys(input);
          for(var idx = 0 ,idx_finish = keys.length; idx < idx_finish; ++idx){
            var key = keys[idx];
            var innerData = input[key];
            try {
              var value = fn$2(innerData);
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
    };
    tmp = [(function (param) {
          return action$1;
        })];
  } else {
    tmp = panic("Unreachable");
  }
  return make("Dict", {
              TAG: /* Dict */7,
              _0: innerStruct
            }, parseActionFactories, tmp, undefined, undefined);
}

function factory$15(innerStruct, defaultValue) {
  var fn = innerStruct.p;
  var tmp;
  if (typeof fn === "number") {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          if (input !== undefined) {
            return Caml_option.valFromOption(input);
          } else {
            return defaultValue;
          }
        })
    };
    tmp = [(function (param) {
          return action;
        })];
  } else if (fn.TAG === /* SyncOperation */0) {
    var fn$1 = fn._0;
    var action$1 = {
      TAG: /* Sync */0,
      _0: (function (input) {
          var output = fn$1(input);
          if (output !== undefined) {
            return Caml_option.valFromOption(output);
          } else {
            return defaultValue;
          }
        })
    };
    tmp = [(function (param) {
          return action$1;
        })];
  } else {
    var fn$2 = fn._0;
    var action$2 = {
      TAG: /* Async */1,
      _0: (function (input) {
          return fn$2(input)().then(function (value) {
                      if (value !== undefined) {
                        return Caml_option.valFromOption(value);
                      } else {
                        return defaultValue;
                      }
                    });
        })
    };
    tmp = [(function (param) {
          return action$2;
        })];
  }
  var action$3 = {
    TAG: /* Sync */0,
    _0: (function (input) {
        var value = Caml_option.some(input);
        var fn = innerStruct.s;
        if (typeof fn === "number") {
          return value;
        } else if (fn.TAG === /* SyncOperation */0) {
          return fn._0(value);
        } else {
          return panic("Unreachable");
        }
      })
  };
  return make("Default", {
              TAG: /* Default */9,
              struct: innerStruct,
              value: defaultValue
            }, tmp, [(function (param) {
                  return action$3;
                })], undefined, undefined);
}

function innerFactory$1(structs) {
  var numberOfStructs = structs.length;
  var noopOps = [];
  var syncOps = [];
  var asyncOps = [];
  for(var idx = 0 ,idx_finish = structs.length; idx < idx_finish; ++idx){
    var innerStruct = structs[idx];
    var fn = innerStruct.p;
    if (typeof fn === "number") {
      noopOps.push(idx);
    } else if (fn.TAG === /* SyncOperation */0) {
      syncOps.push([
            idx,
            fn._0
          ]);
    } else {
      syncOps.push([
            idx,
            fn._0
          ]);
      asyncOps.push(idx);
    }
  }
  var withAsyncOps = asyncOps.length > 0;
  var parseActionFactories = [(function (struct) {
        return {
                TAG: /* Sync */0,
                _0: (function (input) {
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
                      return newArray;
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
              };
      })];
  if (withAsyncOps) {
    var action = {
      TAG: /* Async */1,
      _0: (function (tempArray) {
          return Promise.all(asyncOps.map(function (originalIdx) {
                            return tempArray[originalIdx]().catch(function (exn) {
                                        return $$throw(exn.RE_EXN_ID === Exception ? ({
                                                        RE_EXN_ID: Exception,
                                                        _1: prependLocation(exn._1, originalIdx.toString())
                                                      }) : exn);
                                      });
                          })).then(function (values) {
                      values.forEach(function (value, idx) {
                            var originalIdx = asyncOps[idx];
                            tempArray[originalIdx] = value;
                          });
                      if (tempArray.length <= 1) {
                        return tempArray[0];
                      } else {
                        return tempArray;
                      }
                    });
        })
    };
    parseActionFactories.push(function (param) {
          return action;
        });
  }
  return make("Tuple", {
              TAG: /* Tuple */5,
              _0: structs
            }, parseActionFactories, [(function (param) {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (input) {
                              var inputArray = numberOfStructs === 1 ? [input] : input;
                              var newArray = [];
                              for(var idx = 0; idx < numberOfStructs; ++idx){
                                var innerData = inputArray[idx];
                                var innerStruct = structs[idx];
                                var fn = innerStruct.s;
                                if (typeof fn === "number") {
                                  newArray.push(innerData);
                                } else if (fn.TAG === /* SyncOperation */0) {
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
                        };
                })], undefined, undefined);
}

var factory$16 = callWithArguments(innerFactory$1);

var HackyValidValue = /* @__PURE__ */Caml_exceptions.create("S.Union.HackyValidValue");

function factory$17(structs) {
  if (structs.length < 2) {
    panic("A Union struct factory require at least two structs");
  }
  var serializeActionFactories = [(function (param) {
        return {
                TAG: /* Sync */0,
                _0: (function (input) {
                    var idxRef = 0;
                    var maybeLastErrorRef;
                    var maybeNewValueRef;
                    while(idxRef < structs.length && maybeNewValueRef === undefined) {
                      var idx = idxRef;
                      var innerStruct = structs[idx];
                      try {
                        var fn = innerStruct.s;
                        var newValue;
                        newValue = typeof fn === "number" ? input : (
                            fn.TAG === /* SyncOperation */0 ? fn._0(input) : panic("Unreachable")
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
              };
      })];
  var noopOps = [];
  var syncOps = [];
  var asyncOps = [];
  for(var idx = 0 ,idx_finish = structs.length; idx < idx_finish; ++idx){
    var innerStruct = structs[idx];
    var fn = innerStruct.p;
    if (typeof fn === "number") {
      noopOps.push(undefined);
    } else if (fn.TAG === /* SyncOperation */0) {
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
  var parseActionFactories;
  if (noopOps.length > 0) {
    parseActionFactories = emptyArray;
  } else {
    var action = {
      TAG: /* Sync */0,
      _0: (function (input) {
          var idxRef = 0;
          var errorsRef = [];
          var maybeNewValueRef;
          while(idxRef < syncOps.length && maybeNewValueRef === undefined) {
            var idx = idxRef;
            var match = syncOps[idx];
            try {
              var newValue = match[1](input);
              maybeNewValueRef = Caml_option.some(newValue);
            }
            catch (raw_internalError){
              var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
              if (internalError.RE_EXN_ID === Exception) {
                errorsRef[match[0]] = internalError._1;
                idxRef = idxRef + 1;
              } else {
                throw internalError;
              }
            }
          };
          var match$1 = maybeNewValueRef;
          if (match$1 !== undefined) {
            if (withAsyncOps) {
              return {
                      maybeSyncValue: match$1,
                      tempErrors: errorsRef,
                      originalInput: input
                    };
            } else {
              return Caml_option.valFromOption(match$1);
            }
          } else if (withAsyncOps) {
            return {
                    maybeSyncValue: match$1,
                    tempErrors: errorsRef,
                    originalInput: input
                  };
          } else {
            return raise({
                        TAG: /* InvalidUnion */5,
                        _0: errorsRef.map(toParseError)
                      });
          }
        })
    };
    var parseActionFactories$1 = [(function (param) {
          return action;
        })];
    if (withAsyncOps) {
      var action$1 = {
        TAG: /* Async */1,
        _0: (function (input) {
            var syncValue = input.maybeSyncValue;
            if (syncValue !== undefined) {
              return Promise.resolve(Caml_option.valFromOption(syncValue));
            } else {
              return Promise.all(asyncOps.map(function (param) {
                                var originalIdx = param[0];
                                try {
                                  return param[1](input.originalInput)().then((function (value) {
                                                throw {
                                                      RE_EXN_ID: HackyValidValue,
                                                      _1: value,
                                                      Error: new Error()
                                                    };
                                              }), (function (exn) {
                                                if (exn.RE_EXN_ID !== Exception) {
                                                  return $$throw(exn);
                                                }
                                                var array = input.tempErrors;
                                                array[originalIdx] = exn._1;
                                              }));
                                }
                                catch (raw_internalError){
                                  var internalError = Caml_js_exceptions.internalToOCamlException(raw_internalError);
                                  if (internalError.RE_EXN_ID === Exception) {
                                    var array = input.tempErrors;
                                    return Promise.resolve((array[originalIdx] = internalError._1, undefined));
                                  }
                                  throw internalError;
                                }
                              })).then((function (param) {
                            return raise({
                                        TAG: /* InvalidUnion */5,
                                        _0: input.tempErrors.map(toParseError)
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
      };
      parseActionFactories$1.push(function (param) {
            return action$1;
          });
    }
    parseActionFactories = parseActionFactories$1;
  }
  return make("Union", {
              TAG: /* Union */6,
              _0: structs
            }, parseActionFactories, serializeActionFactories, undefined, undefined);
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

function json(innerStruct) {
  return advancedTransform(transform(factory$5(undefined), (function (jsonString) {
                    try {
                      return JSON.parse(jsonString);
                    }
                    catch (raw_obj){
                      var obj = Caml_js_exceptions.internalToOCamlException(raw_obj);
                      if (obj.RE_EXN_ID === Js_exn.$$Error) {
                        return raise$2(Belt_Option.getWithDefault(obj._1.message, "Failed to parse JSON"));
                      }
                      throw obj;
                    }
                  }), (function (prim) {
                    return JSON.stringify(prim);
                  }), undefined), (function (param) {
                var match = innerStruct.p;
                var tmp;
                tmp = typeof match === "number" || match.TAG === /* SyncOperation */0 ? false : true;
                if (tmp) {
                  return {
                          TAG: /* Async */1,
                          _0: (function (parsedJson) {
                              return parseAsyncWith(parsedJson, innerStruct).then(function (result) {
                                          if (result.TAG === /* Ok */0) {
                                            return result._0;
                                          }
                                          throw {
                                                RE_EXN_ID: Exception,
                                                _1: result._0,
                                                Error: new Error()
                                              };
                                        });
                            })
                        };
                } else {
                  return {
                          TAG: /* Sync */0,
                          _0: (function (parsedJson) {
                              var value = parseWith(parsedJson, innerStruct);
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
                }
              }), (function (param) {
                return {
                        TAG: /* Sync */0,
                        _0: (function (value) {
                            var unknown = serializeWith(value, innerStruct);
                            if (unknown.TAG === /* Ok */0) {
                              return unknown._0;
                            }
                            throw {
                                  RE_EXN_ID: Exception,
                                  _1: unknown._0,
                                  Error: new Error()
                                };
                          })
                      };
              }), undefined);
}

var $$Error = {
  prependLocation: prependLocation$1,
  raiseCustom: raiseCustom,
  raise: raise$2,
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
            n: struct.n,
            t: struct.t,
            pf: struct.pf,
            sf: struct.sf,
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
exports.advancedTransform = advancedTransform;
exports.custom = custom;
exports.refine = refine;
exports.asyncRefine = asyncRefine;
exports.parseWith = parseWith;
exports.parseAsyncWith = parseAsyncWith;
exports.parseAsyncInStepsWith = parseAsyncInStepsWith;
exports.serializeWith = serializeWith;
exports.isAsyncParse = isAsyncParse;
exports.isAsyncSerialize = isAsyncSerialize;
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
