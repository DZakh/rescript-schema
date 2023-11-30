# Contributing

When it comes to open source, there are different ways you can contribute, all of which are valuable. Here's few guidelines that should help you as you prepare your contribution.

## Initial steps

Before you start working on a contribution, create an issue describing what you want to build. It's possible someone else is already working on something similar, or perhaps there is a reason that feature isn't implemented. The maintainers will point you in the right direction.

## Development

The following steps will get you setup to contribute changes to this repo:

1. Fork this repo.
2. Clone your forked repo: `git clone git@github.com:{your_username}/rescript-schema.git`
3. Install [pnpm](https://pnpm.io/) if not available `npm i -g pnpm@7.11.0`
4. Run `pnpm i` to install dependencies.
5. Start playing with the code!

## PPX

### With Dune

Make sure running the below commands in `packages/rescript-schema-ppx/src`.

1. Create a sandbox with opam

```
opam switch create rescript-schema-ppx 4.12.1
```

2. Install dependencies

```
opam install . --deps-only
```

3. Build

```
dune build --watch
```

4. Test

Make sure running tests

```
(run compiler for lib)
npm run res
(run compiler for tests)
npm run test:res
(run tests in watch mode)
npm run test -- --watch
```

## License

By contributing your code to the rescript-schema GitHub repository, you agree to license your contribution under the MIT license.
