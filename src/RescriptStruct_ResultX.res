let mapError = (result, fn) =>
  switch result {
  | Ok(_) as ok => ok
  | Error(error) => Error(fn(error))
  }

module Array = {
  let mapi = (array, cb) => {
    let newArray = []
    let maybeErrorRef = ref(None)
    array
    ->Js.Array2.findi((item, idx) => {
      switch cb(item, idx) {
      | Ok(value) => {
          newArray->Js.Array2.push(value)->ignore
          false
        }
      | Error(error) => {
          maybeErrorRef.contents = Some(error)
          true
        }
      }
    })
    ->ignore
    switch maybeErrorRef.contents {
    | Some(error) => Error(error)
    | None => Ok(newArray)
    }
  }
}

module Dict = {
  let map = (dict, cb) => {
    let newDict = Js.Dict.empty()
    let maybeErrorRef = ref(None)
    dict
    ->Js.Dict.keys
    ->Js.Array2.find(key => {
      let item = dict->Js.Dict.unsafeGet(key)
      switch cb(item, key) {
      | Ok(value) => {
          newDict->Js.Dict.set(key, value)->ignore
          false
        }
      | Error(error) => {
          maybeErrorRef.contents = Some(error)
          true
        }
      }
    })
    ->ignore
    switch maybeErrorRef.contents {
    | Some(error) => Error(error)
    | None => Ok(newDict)
    }
  }
}
