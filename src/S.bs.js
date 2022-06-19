'use strict';

var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Js_dict = require("rescript/lib/js/js_dict.js");
var Js_types = require("rescript/lib/js/js_types.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");
var Caml_option = require("rescript/lib/js/caml_option.js");
var Caml_js_exceptions = require("rescript/lib/js/caml_js_exceptions.js");
var RescriptStruct_Error = require("./RescriptStruct_Error.bs.js");

function classify(struct) {
  return struct.tagged_t;
}

function toString(tagged_t) {
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
            if (literal === /* EmptyNull */0) {
              return "EmptyNull Literal (null)";
            } else {
              return "EmptyOption Literal (undefined)";
            }
          }
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
      case /* Option */1 :
          return "Option";
      case /* Null */2 :
          return "Null";
      case /* Array */3 :
          return "Array";
      case /* Record */4 :
          return "Record";
      case /* Union */5 :
          return "Union";
      case /* Dict */6 :
          return "Dict";
      case /* Deprecated */7 :
          return "Deprecated";
      case /* Default */8 :
          return "Default";
      
    }
  }
}

function makeUnexpectedTypeError(input, struct) {
  var typesTagged = Js_types.classify(input);
  var structTagged = struct.tagged_t;
  var got;
  if (typeof typesTagged === "number") {
    switch (typesTagged) {
      case /* JSFalse */0 :
      case /* JSTrue */1 :
          got = "Bool";
          break;
      case /* JSNull */2 :
          got = "Null";
          break;
      case /* JSUndefined */3 :
          got = "Option";
          break;
      
    }
  } else {
    switch (typesTagged.TAG | 0) {
      case /* JSNumber */0 :
          got = "Float";
          break;
      case /* JSString */1 :
          got = "String";
          break;
      case /* JSFunction */2 :
          got = "Function";
          break;
      case /* JSObject */3 :
          got = "Object";
          break;
      case /* JSSymbol */4 :
          got = "Symbol";
          break;
      
    }
  }
  var expected = toString(structTagged);
  return function (param) {
    return RescriptStruct_Error.UnexpectedType.make(expected, got, param);
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
        maybeErrorRef = Caml_option.some(newValue._0);
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
            _0: Caml_option.valFromOption(error)
          };
  } else {
    return {
            TAG: /* Ok */0,
            _0: valueRef
          };
  }
}

function parseInner(struct, any, mode) {
  var constructors = struct.maybeConstructors;
  if (constructors !== undefined) {
    return applyOperations(constructors, any, mode, struct);
  } else {
    return {
            TAG: /* Error */1,
            _0: RescriptStruct_Error.MissingConstructor.make(undefined)
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
            _0: RescriptStruct_Error.toString(result._0)
          };
  }
}

function serializeInner(struct, value, mode) {
  var destructors = struct.maybeDestructors;
  if (destructors !== undefined) {
    return applyOperations(destructors, value, mode, struct);
  } else {
    return {
            TAG: /* Error */1,
            _0: RescriptStruct_Error.MissingDestructor.make(undefined)
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
            _0: RescriptStruct_Error.toString(result._0)
          };
  }
}

var constructors = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      })
  }];

var destructors = [];

var constructors$1 = [];

var destructors$1 = [];

var constructors$2 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "string") {
          return ;
        } else {
          return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
        }
      })
  }];

var destructors$2 = [];

var constructors$3 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "boolean") {
          return ;
        } else {
          return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
        }
      })
  }];

var destructors$3 = [];

var constructors$4 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "number") {
          return ;
        } else {
          return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
        }
      })
  }];

var destructors$4 = [];

var constructors$5 = [{
    TAG: /* Refinement */1,
    _0: (function (input, struct) {
        if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
          return ;
        } else {
          return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
        }
      })
  }];

var destructors$5 = [];

var constructors$6 = [{
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

var destructors$6 = [{
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

var constructors$7 = [{
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

var destructors$7 = [{
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

var constructors$8 = [{
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

var destructors$8 = [{
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

var constructors$9 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var maybeRefinementError;
        if (mode) {
          maybeRefinementError = undefined;
        } else {
          var match = Array.isArray(input);
          maybeRefinementError = match ? undefined : Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
        }
        if (maybeRefinementError !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: Caml_option.valFromOption(maybeRefinementError)
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
            maybeErrorRef = Caml_option.some(RescriptStruct_Error.prependIndex(value._0, idx));
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: Caml_option.valFromOption(error)
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newArray
                };
        }
      })
  }];

var destructors$9 = [{
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
            maybeErrorRef = Caml_option.some(RescriptStruct_Error.prependIndex(value._0, idx));
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: Caml_option.valFromOption(error)
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newArray
                };
        }
      })
  }];

var constructors$10 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var maybeRefinementError;
        if (mode) {
          maybeRefinementError = undefined;
        } else {
          var match = Object.prototype.toString.call(input) === "[object Object]";
          maybeRefinementError = match ? undefined : Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
        }
        if (maybeRefinementError !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: Caml_option.valFromOption(maybeRefinementError)
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
            maybeErrorRef = Caml_option.some(RescriptStruct_Error.prependField(value._0, key));
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: Caml_option.valFromOption(error)
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newDict
                };
        }
      })
  }];

var destructors$10 = [{
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
            maybeErrorRef = Caml_option.some(RescriptStruct_Error.prependField(value._0, key));
          }
        };
        var error = maybeErrorRef;
        if (error !== undefined) {
          return {
                  TAG: /* Error */1,
                  _0: Caml_option.valFromOption(error)
                };
        } else {
          return {
                  TAG: /* Ok */0,
                  _0: newDict
                };
        }
      })
  }];

var constructors$11 = [{
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

var destructors$11 = [{
    TAG: /* Transform */0,
    _0: (function (input, struct, mode) {
        var match = struct.tagged_t;
        return serializeInner(match.struct, Caml_option.some(input), mode);
      })
  }];

var optionValueRefinement = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (input !== undefined) {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Serializing */0));
      }
      
    })
};

var literalValueRefinement = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      var expectedValue = struct.tagged_t._0._0;
      if (expectedValue === input) {
        return ;
      } else {
        return Caml_option.some(RescriptStruct_Error.UnexpectedValue.make(expectedValue, input, /* Serializing */0));
      }
    })
};

var literalValueRefinement$1 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      var expectedValue = struct.tagged_t._0._0;
      if (expectedValue === input) {
        return ;
      } else {
        return Caml_option.some(RescriptStruct_Error.UnexpectedValue.make(expectedValue, input, /* Parsing */1));
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

var constructorRefinement = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (input === null) {
        return ;
      } else {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      }
    })
};

var destructorTransform = {
  TAG: /* Transform */0,
  _0: (function (param, param$1, param$2) {
      return {
              TAG: /* Ok */0,
              _0: null
            };
    })
};

var constructorRefinement$1 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (input === undefined) {
        return ;
      } else {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      }
    })
};

var destructorTransform$1 = {
  TAG: /* Transform */0,
  _0: (function (param, param$1, param$2) {
      return {
              TAG: /* Ok */0,
              _0: undefined
            };
    })
};

var constructorRefinement$2 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "boolean") {
        return ;
      } else {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      }
    })
};

var constructorRefinement$3 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "string") {
        return ;
      } else {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      }
    })
};

var constructorRefinement$4 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "number") {
        return ;
      } else {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      }
    })
};

var constructorRefinement$5 = {
  TAG: /* Refinement */1,
  _0: (function (input, struct) {
      if (typeof input === "number" && input < 2147483648 && input > -2147483649 && input === Math.trunc(input)) {
        return ;
      } else {
        return Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
      }
    })
};

function factory(innerLiteral) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  if (typeof innerLiteral === "number") {
    if (innerLiteral === /* EmptyNull */0) {
      return {
              tagged_t: tagged_t,
              maybeConstructors: [
                constructorRefinement,
                {
                  TAG: /* Transform */0,
                  _0: (function (param, param$1, param$2) {
                      return {
                              TAG: /* Ok */0,
                              _0: undefined
                            };
                    })
                }
              ],
              maybeDestructors: [
                optionValueRefinement,
                destructorTransform
              ],
              maybeMetadata: undefined
            };
    } else {
      return {
              tagged_t: tagged_t,
              maybeConstructors: [
                constructorRefinement$1,
                {
                  TAG: /* Transform */0,
                  _0: (function (param, param$1, param$2) {
                      return {
                              TAG: /* Ok */0,
                              _0: undefined
                            };
                    })
                }
              ],
              maybeDestructors: [
                optionValueRefinement,
                destructorTransform$1
              ],
              maybeMetadata: undefined
            };
    }
  }
  switch (innerLiteral.TAG | 0) {
    case /* String */0 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$3,
                  literalValueRefinement$1,
                  transformToLiteralValue
                ],
                maybeDestructors: [
                  literalValueRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    case /* Int */1 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$5,
                  literalValueRefinement$1,
                  transformToLiteralValue
                ],
                maybeDestructors: [
                  literalValueRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    case /* Float */2 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$4,
                  literalValueRefinement$1,
                  transformToLiteralValue
                ],
                maybeDestructors: [
                  literalValueRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    case /* Bool */3 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$2,
                  literalValueRefinement$1,
                  transformToLiteralValue
                ],
                maybeDestructors: [
                  literalValueRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    
  }
}

function factory$1(innerLiteral, variant) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  var constructorTransform = {
    TAG: /* Transform */0,
    _0: (function (param, param$1, param$2) {
        return {
                TAG: /* Ok */0,
                _0: variant
              };
      })
  };
  var destructorRefinement = {
    TAG: /* Refinement */1,
    _0: (function (input, param) {
        if (input === variant) {
          return ;
        } else {
          return Caml_option.some(RescriptStruct_Error.UnexpectedValue.make(variant, input, /* Serializing */0));
        }
      })
  };
  if (typeof innerLiteral === "number") {
    if (innerLiteral === /* EmptyNull */0) {
      return {
              tagged_t: tagged_t,
              maybeConstructors: [
                constructorRefinement,
                constructorTransform
              ],
              maybeDestructors: [
                destructorRefinement,
                destructorTransform
              ],
              maybeMetadata: undefined
            };
    } else {
      return {
              tagged_t: tagged_t,
              maybeConstructors: [
                constructorRefinement$1,
                constructorTransform
              ],
              maybeDestructors: [
                destructorRefinement,
                destructorTransform$1
              ],
              maybeMetadata: undefined
            };
    }
  }
  switch (innerLiteral.TAG | 0) {
    case /* String */0 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$3,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [
                  destructorRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    case /* Int */1 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$5,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [
                  destructorRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    case /* Float */2 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$4,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [
                  destructorRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    case /* Bool */3 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$2,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [
                  destructorRefinement,
                  transformToLiteralValue
                ],
                maybeMetadata: undefined
              };
    
  }
}

var constructorTransform = {
  TAG: /* Transform */0,
  _0: (function (param, param$1, param$2) {
      return {
              TAG: /* Ok */0,
              _0: undefined
            };
    })
};

function factory$2(innerLiteral) {
  var tagged_t = {
    TAG: /* Literal */0,
    _0: innerLiteral
  };
  if (typeof innerLiteral === "number") {
    if (innerLiteral === /* EmptyNull */0) {
      return {
              tagged_t: tagged_t,
              maybeConstructors: [
                constructorRefinement,
                constructorTransform
              ],
              maybeDestructors: [destructorTransform],
              maybeMetadata: undefined
            };
    } else {
      return {
              tagged_t: tagged_t,
              maybeConstructors: [
                constructorRefinement$1,
                constructorTransform
              ],
              maybeDestructors: [destructorTransform$1],
              maybeMetadata: undefined
            };
    }
  }
  switch (innerLiteral.TAG | 0) {
    case /* String */0 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$3,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [transformToLiteralValue],
                maybeMetadata: undefined
              };
    case /* Int */1 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$5,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [transformToLiteralValue],
                maybeMetadata: undefined
              };
    case /* Float */2 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$4,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [transformToLiteralValue],
                maybeMetadata: undefined
              };
    case /* Bool */3 :
        return {
                tagged_t: tagged_t,
                maybeConstructors: [
                  constructorRefinement$2,
                  literalValueRefinement$1,
                  constructorTransform
                ],
                maybeDestructors: [transformToLiteralValue],
                maybeMetadata: undefined
              };
    
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

function make(recordConstructor) {
  return [{
            TAG: /* Transform */0,
            _0: (function (input, struct, mode) {
                var maybeRefinementError;
                if (mode) {
                  maybeRefinementError = undefined;
                } else {
                  var match = Object.prototype.toString.call(input) === "[object Object]";
                  maybeRefinementError = match ? undefined : Caml_option.some(makeUnexpectedTypeError(input, struct)(/* Parsing */1));
                }
                if (maybeRefinementError !== undefined) {
                  return {
                          TAG: /* Error */1,
                          _0: Caml_option.valFromOption(maybeRefinementError)
                        };
                }
                var match$1 = struct.tagged_t;
                var fieldNames = match$1.fieldNames;
                var fields = match$1.fields;
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
                    maybeErrorRef = Caml_option.some(RescriptStruct_Error.prependField(value._0, fieldName));
                  }
                };
                var error = maybeErrorRef;
                var fieldValuesResult = error !== undefined ? ({
                      TAG: /* Error */1,
                      _0: Caml_option.valFromOption(error)
                    }) : ({
                      TAG: /* Ok */0,
                      _0: newArray
                    });
                var result;
                if (match$1.unknownKeys || mode || fieldValuesResult.TAG !== /* Ok */0) {
                  result = fieldValuesResult;
                } else {
                  var excessKey = getMaybeExcessKey(input, fields);
                  result = excessKey !== undefined ? ({
                        TAG: /* Error */1,
                        _0: RescriptStruct_Error.ExcessField.make(excessKey)
                      }) : fieldValuesResult;
                }
                if (result.TAG !== /* Ok */0) {
                  return result;
                }
                var fieldValues = result._0;
                var fieldValuesTuple = fieldValues.length === 1 ? fieldValues[0] : fieldValues;
                var fn = RescriptStruct_Error.ParsingFailed.make;
                var result$1 = Curry._1(recordConstructor, fieldValuesTuple);
                if (result$1.TAG === /* Ok */0) {
                  return result$1;
                } else {
                  return {
                          TAG: /* Error */1,
                          _0: Curry._1(fn, result$1._0)
                        };
                }
              })
          }];
}

function make$1(recordDestructor) {
  return [{
            TAG: /* Transform */0,
            _0: (function (input, struct, mode) {
                var match = struct.tagged_t;
                var fieldNames = match.fieldNames;
                var fields = match.fields;
                var fn = RescriptStruct_Error.SerializingFailed.make;
                var result = Curry._1(recordDestructor, input);
                var result$1;
                result$1 = result.TAG === /* Ok */0 ? result : ({
                      TAG: /* Error */1,
                      _0: Curry._1(fn, result._0)
                    });
                if (result$1.TAG !== /* Ok */0) {
                  return result$1;
                }
                var fieldValuesTuple = result$1._0;
                var unknown = {};
                var fieldValues = fieldNames.length === 1 ? [fieldValuesTuple] : fieldValuesTuple;
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
                    maybeErrorRef = Caml_option.some(RescriptStruct_Error.prependField(unknownFieldValue._0, fieldName));
                  }
                };
                var error = maybeErrorRef;
                if (error !== undefined) {
                  return {
                          TAG: /* Error */1,
                          _0: Caml_option.valFromOption(error)
                        };
                } else {
                  return {
                          TAG: /* Ok */0,
                          _0: unknown
                        };
                }
              })
          }];
}

function factory$3(fieldsArray, maybeRecordConstructor, maybeRecordDestructor, param) {
  if (maybeRecordConstructor === undefined && maybeRecordDestructor === undefined) {
    RescriptStruct_Error.MissingConstructorAndDestructor.raise("Record struct factory");
  }
  var fields = Js_dict.fromArray(fieldsArray);
  return {
          tagged_t: {
            TAG: /* Record */4,
            fields: fields,
            fieldNames: Object.keys(fields),
            unknownKeys: /* Strict */0
          },
          maybeConstructors: maybeRecordConstructor !== undefined ? Caml_option.some(make(Caml_option.valFromOption(maybeRecordConstructor))) : undefined,
          maybeDestructors: maybeRecordDestructor !== undefined ? Caml_option.some(make$1(Caml_option.valFromOption(maybeRecordDestructor))) : undefined,
          maybeMetadata: undefined
        };
}

function strip(struct) {
  var tagged_t = struct.tagged_t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return RescriptStruct_Error.UnknownKeysRequireRecord.raise(undefined);
  } else {
    return {
            tagged_t: {
              TAG: /* Record */4,
              fields: tagged_t.fields,
              fieldNames: tagged_t.fieldNames,
              unknownKeys: /* Strip */1
            },
            maybeConstructors: struct.maybeConstructors,
            maybeDestructors: struct.maybeDestructors,
            maybeMetadata: struct.maybeMetadata
          };
  }
}

function strict(struct) {
  var tagged_t = struct.tagged_t;
  if (typeof tagged_t === "number" || tagged_t.TAG !== /* Record */4) {
    return RescriptStruct_Error.UnknownKeysRequireRecord.raise(undefined);
  } else {
    return {
            tagged_t: {
              TAG: /* Record */4,
              fields: tagged_t.fields,
              fieldNames: tagged_t.fieldNames,
              unknownKeys: /* Strict */0
            },
            maybeConstructors: struct.maybeConstructors,
            maybeDestructors: struct.maybeDestructors,
            maybeMetadata: struct.maybeMetadata
          };
  }
}

function record1(fields) {
  var partial_arg = [fields];
  return function (param, param$1, param$2) {
    return factory$3(partial_arg, param, param$1, param$2);
  };
}

function never(param) {
  return {
          tagged_t: /* Never */0,
          maybeConstructors: constructors,
          maybeDestructors: destructors,
          maybeMetadata: undefined
        };
}

function unknown(param) {
  return {
          tagged_t: /* Unknown */1,
          maybeConstructors: constructors$1,
          maybeDestructors: destructors$1,
          maybeMetadata: undefined
        };
}

function string(param) {
  return {
          tagged_t: /* String */2,
          maybeConstructors: constructors$2,
          maybeDestructors: destructors$2,
          maybeMetadata: undefined
        };
}

function bool(param) {
  return {
          tagged_t: /* Bool */5,
          maybeConstructors: constructors$3,
          maybeDestructors: destructors$3,
          maybeMetadata: undefined
        };
}

function $$int(param) {
  return {
          tagged_t: /* Int */3,
          maybeConstructors: constructors$5,
          maybeDestructors: destructors$5,
          maybeMetadata: undefined
        };
}

function $$float(param) {
  return {
          tagged_t: /* Float */4,
          maybeConstructors: constructors$4,
          maybeDestructors: destructors$4,
          maybeMetadata: undefined
        };
}

function $$null(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Null */2,
            _0: innerStruct
          },
          maybeConstructors: constructors$6,
          maybeDestructors: destructors$6,
          maybeMetadata: undefined
        };
}

function option(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Option */1,
            _0: innerStruct
          },
          maybeConstructors: constructors$7,
          maybeDestructors: destructors$7,
          maybeMetadata: undefined
        };
}

function deprecated(maybeMessage, innerStruct) {
  return {
          tagged_t: {
            TAG: /* Deprecated */7,
            struct: innerStruct,
            maybeMessage: maybeMessage
          },
          maybeConstructors: constructors$8,
          maybeDestructors: destructors$8,
          maybeMetadata: undefined
        };
}

function array(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Array */3,
            _0: innerStruct
          },
          maybeConstructors: constructors$9,
          maybeDestructors: destructors$9,
          maybeMetadata: undefined
        };
}

function dict(innerStruct) {
  return {
          tagged_t: {
            TAG: /* Dict */6,
            _0: innerStruct
          },
          maybeConstructors: constructors$10,
          maybeDestructors: destructors$10,
          maybeMetadata: undefined
        };
}

function $$default(innerStruct, defaultValue) {
  return {
          tagged_t: {
            TAG: /* Default */8,
            struct: innerStruct,
            value: defaultValue
          },
          maybeConstructors: constructors$11,
          maybeDestructors: destructors$11,
          maybeMetadata: undefined
        };
}

function json(struct) {
  return {
          tagged_t: /* String */2,
          maybeConstructors: constructors$2.concat([{
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
                          result = {
                            TAG: /* Error */1,
                            _0: RescriptStruct_Error.ParsingFailed.make(Belt_Option.getWithDefault(maybeMessage, "Syntax error"))
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
          maybeDestructors: [{
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
              }].concat(destructors$2),
          maybeMetadata: undefined
        };
}

function refine(struct, maybeConstructorRefine, maybeDestructorRefine, param) {
  if (maybeConstructorRefine === undefined && maybeDestructorRefine === undefined) {
    RescriptStruct_Error.MissingConstructorAndDestructor.raise("struct factory Refine");
  }
  var match = struct.maybeConstructors;
  var match$1 = struct.maybeDestructors;
  return {
          tagged_t: struct.tagged_t,
          maybeConstructors: match !== undefined && maybeConstructorRefine !== undefined ? match.concat([{
                    TAG: /* Refinement */1,
                    _0: (function (input, param) {
                        var fn = RescriptStruct_Error.ParsingFailed.make;
                        var option = Curry._1(maybeConstructorRefine, input);
                        if (option !== undefined) {
                          return Caml_option.some(Curry._1(fn, Caml_option.valFromOption(option)));
                        }
                        
                      })
                  }]) : undefined,
          maybeDestructors: match$1 !== undefined && maybeDestructorRefine !== undefined ? [{
                  TAG: /* Refinement */1,
                  _0: (function (input, param) {
                      var fn = RescriptStruct_Error.SerializingFailed.make;
                      var option = Curry._1(maybeDestructorRefine, input);
                      if (option !== undefined) {
                        return Caml_option.some(Curry._1(fn, Caml_option.valFromOption(option)));
                      }
                      
                    })
                }].concat(match$1) : undefined,
          maybeMetadata: struct.maybeMetadata
        };
}

function transform(struct, maybeTransformationConstructor, maybeTransformationDestructor, param) {
  if (maybeTransformationConstructor === undefined && maybeTransformationDestructor === undefined) {
    RescriptStruct_Error.MissingConstructorAndDestructor.raise("struct factory Transform");
  }
  var match = struct.maybeConstructors;
  var match$1 = struct.maybeDestructors;
  return {
          tagged_t: struct.tagged_t,
          maybeConstructors: match !== undefined && maybeTransformationConstructor !== undefined ? match.concat([{
                    TAG: /* Transform */0,
                    _0: (function (input, param, param$1) {
                        var fn = RescriptStruct_Error.ParsingFailed.make;
                        var result = Curry._1(maybeTransformationConstructor, input);
                        if (result.TAG === /* Ok */0) {
                          return result;
                        } else {
                          return {
                                  TAG: /* Error */1,
                                  _0: Curry._1(fn, result._0)
                                };
                        }
                      })
                  }]) : undefined,
          maybeDestructors: match$1 !== undefined && maybeTransformationDestructor !== undefined ? [{
                  TAG: /* Transform */0,
                  _0: (function (input, param, param$1) {
                      var fn = RescriptStruct_Error.SerializingFailed.make;
                      var result = Curry._1(maybeTransformationDestructor, input);
                      if (result.TAG === /* Ok */0) {
                        return result;
                      } else {
                        return {
                                TAG: /* Error */1,
                                _0: Curry._1(fn, result._0)
                              };
                      }
                    })
                }].concat(match$1) : undefined,
          maybeMetadata: struct.maybeMetadata
        };
}

var constructors$12 = [{
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

var destructors$12 = [{
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

function factory$4(structs) {
  if (structs.length < 2) {
    RescriptStruct_Error.UnionLackingStructs.raise(undefined);
  }
  return {
          tagged_t: {
            TAG: /* Union */5,
            _0: structs
          },
          maybeConstructors: constructors$12,
          maybeDestructors: destructors$12,
          maybeMetadata: undefined
        };
}

var literal = factory;

var literalVariant = factory$1;

var literalUnit = factory$2;

var union = factory$4;

var transformUnknown = transform;

var Record = {
  factory: factory$3,
  strip: strip,
  strict: strict
};

var record2 = factory$3;

var record3 = factory$3;

var record4 = factory$3;

var record5 = factory$3;

var record6 = factory$3;

var record7 = factory$3;

var record8 = factory$3;

var record9 = factory$3;

var record10 = factory$3;

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
            maybeConstructors: struct.maybeConstructors,
            maybeDestructors: struct.maybeDestructors,
            maybeMetadata: Caml_option.some(dictUnsafeSet(existingContent, funarg.namespace, content))
          };
  };
  return {
          get: get,
          set: set
        };
}

exports.never = never;
exports.unknown = unknown;
exports.string = string;
exports.bool = bool;
exports.$$int = $$int;
exports.$$float = $$float;
exports.literal = literal;
exports.literalVariant = literalVariant;
exports.literalUnit = literalUnit;
exports.array = array;
exports.dict = dict;
exports.option = option;
exports.$$null = $$null;
exports.deprecated = deprecated;
exports.$$default = $$default;
exports.default = $$default;
exports.__esModule = true;
exports.json = json;
exports.transform = transform;
exports.union = union;
exports.transformUnknown = transformUnknown;
exports.refine = refine;
exports.parseWith = parseWith;
exports.serializeWith = serializeWith;
exports.Record = Record;
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
exports.classify = classify;
exports.MakeMetadata = MakeMetadata;
/* RescriptStruct_Error Not a pure module */
