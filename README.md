Graphql Phoenix API made by great book `Craft GraphQL APIs in Elixir with Absinthe`. This great book is covering topics like
querying, mutations, live subscriptions, authentication/authorization, performance isseus caused by eg. N+1 queries in associations, structing codebase to be more
cleaner, readable and so on.

The repository is containing 3 projects. `basic-ui` and `plate-slate-apollo-ui` are simple javascript clients (each used different tech.).
The most important is `phoenix-graphql` which is API with GraphQL written in Phoenix framework. The phoenix-graphql project is also including
admin simple interface which is communicating with data not by DB connection but directly via existing GraphQL requests and prepared
schema.

## Run API
Go to the `phoenix-graphql` folder and run:

```
$> docker-compose up -d
$> mix deps.get
$> mix ecto.setup
$> mix phx.server
```

Then you can visit `graphiql` interface for palaying with API and schema on `http://localhost:4000/graphiql`.


Some of the REST queries are also prepared in `elixir-graphql.rest` file.

Some of my internal comments are inside `phoenix-graphql/README.md`.
