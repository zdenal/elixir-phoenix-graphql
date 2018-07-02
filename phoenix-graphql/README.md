### dev/support/seeds.ex
Seeds for initial filling up DB (`mix ecto.setup` or `mix ecto.reset` will automatically run them).

### lib/plate_slate_web/
Logic related with domains and logic

### lib/plate_slate_web/
Logic related with application web (api/GraphQL, admin serverside UI, ..)

  - router.ex  Settings of routes (/admin, /api, /graphiql, ..)
  - admin_auth.ex  Plug used in router.ex to handle authentication for admin serverside UI
  - context.ex  Plug used in router.ex to handle authentication for api/GraphQL endpoints
  - resolvers/***  Resolver layer used to link GraphQL layer with application logic layer
  - schema.ex  Defining schema for GraphQL
  - schema/  Middlewares, types used in `schema.ex`. For better structuring (decomposing)
    and readability

  - channels/user_socket.ex  Defining socket for live stream subscriptions
  - endpoint.ex  Registering `user_socket.ex`. Our PlateSlateWeb.UserSocket is available at `/socket`, based on the setup we did in PlateSlateWeb.Endpoint

  - controllers/, templates/, views/  Almost the same as in RoR framework.

### Resolvers
They are getting 3 arguments:
 - 1st `parent value` (parent object from nested object ... eg. user object for nested field orders in user object )
 - 2nd `aruments` ... map from set arguments on field
 - 3rd `context` ... setted context from eg. some middleware (loader, current_user, ...)

They are returnig `value / parent value` for API result / nested field (as parent value for nested fields see in `ordering resolver`
`order_history/3` which is returning value (parent value) for nested field `orders` with resolvers `orders/3`

## TODO
  - take a better look into Dataloader functionallity.
