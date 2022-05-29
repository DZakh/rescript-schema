module Array = {
  let mapi = (array, fn) => {
    let newArray = []
    let idxRef = ref(0)
    let maybeErrorRef = ref(None)

    while idxRef.contents < array->Js.Array2.length && maybeErrorRef.contents == None {
      let idx = idxRef.contents
      let item = array->Js.Array2.unsafe_get(idx)
      switch fn(. item, idx) {
      | Ok(value) => {
          newArray->Js.Array2.push(value)->ignore
          idxRef.contents = idxRef.contents + 1
        }
      | Error(_) as error => maybeErrorRef.contents = Some(error)
      }
    }

    switch maybeErrorRef.contents {
    | Some(error) => error
    | None => Ok(newArray)
    }
  }
}

module Dict = {
  let map = (dict, fn) => {
    let newDict = Js.Dict.empty()
    let keys = dict->Js.Dict.keys
    let idxRef = ref(0)
    let maybeErrorRef = ref(None)

    while idxRef.contents < keys->Js.Array2.length && maybeErrorRef.contents == None {
      let idx = idxRef.contents
      let key = keys->Js.Array2.unsafe_get(idx)
      let item = dict->Js.Dict.unsafeGet(key)
      switch fn(. item, key) {
      | Ok(value) => {
          newDict->Js.Dict.set(key, value)->ignore
          idxRef.contents = idxRef.contents + 1
        }
      | Error(_) as error => maybeErrorRef.contents = Some(error)
      }
    }

    switch maybeErrorRef.contents {
    | Some(error) => error
    | None => Ok(newDict)
    }
  }
}
