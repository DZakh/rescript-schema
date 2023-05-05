@struct
type simpleRecord = {
  label: string,
  value: int,
}

@struct
type recordWithAlias = {
  label: string,
  value: int,
}
@struct
type recordWithOptional = {
  label: option<string>,
  value?: int,
}
