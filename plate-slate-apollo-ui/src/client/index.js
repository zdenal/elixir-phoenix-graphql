import ApolloClient from "apollo-client";
import { InMemoryCache } from "apollo-cache-inmemory";
import { ApolloLink } from "apollo-link";
import { createHttpLink } from "apollo-link-http";
import { hasSubscription } from "@jumpn/utils-graphql";

import absintheSocketLink from "./absinthe-socket-link";

// The hasSubscription() function, from one of @absinthe/socket’s dependencies,
// is a handy utility that lets us check our GraphQL for a subscription.
// In the event one is found, we use our WebSocket link.
// Otherwise, we send the request over HTTP to the configured URL.
const link = new ApolloLink.split(
  operation => hasSubscription(operation.query),
  absintheSocketLink,
  createHttpLink({uri: "http://localhost:4000/api/graphql"})
);

export default new ApolloClient({
  link,
  cache: new InMemoryCache()
});
