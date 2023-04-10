## PPX

### With Dune

Make sure running the below commands in `/src`.

1. Create a sandbox with opam

```
opam switch create struct 4.12.1
```

2. Install dependencies

```
opam install . --deps-only
```

3. Build

```
dune build
```

4. Test

Make sure running tests in `/test`

```
cd test

(install dependencies)
npm ci

(build --watch)
npm run res:dev

(run test --watch)
npm run test:dev
```
