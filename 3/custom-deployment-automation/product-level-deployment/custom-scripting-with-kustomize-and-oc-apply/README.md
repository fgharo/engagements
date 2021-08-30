```
cd scripts
```

Scenario 1: Seed a new namespace called dev1 with deployment applications defined in dev1 folder of deployConfig.

```
./copy-resources-from-src-env-folder-to-dest-namespace.sh dev1 dev1
```


Scenario 2: Seed a new namespace called qa1 with deployment applications defined in qa1 folder of deployConfig.
```
./copy-resources-from-src-env-folder-to-dest-namespace.sh qa1 qa1
```

Scenario 3: Copy qa1 deployment configurations to a namespace called qa2
```
./copy-resources-from-src-env-folder-to-dest-namespace.sh qa1 qa2
```