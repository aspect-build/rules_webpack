This e2e demonstrates a workaround for certain webpack errors that can occur
when a webpack configuration file imports plugins from the `webpack` package,
most notably the error:

```
TypeError: The 'compilation' argument must be an instance of Compilation
```

Which is caused by rules_webpack's copy of webpack creating the configuration,
but the plugins executing in the user workspace's linked version of webpack,
and the presence of an `instanceof` check. This error occurs even if the
version of webpack used by rules_webpack and the user workspace's version
are the same.
