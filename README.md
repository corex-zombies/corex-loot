# corex-loot

> World loot containers with per-type tables and fixed world locations.

Part of the [COREX Framework](https://github.com/corex-zombies).

## Install

Drop the `corex-loot` folder into:
```
server-data/resources/[corex]/corex-loot/
```

Make sure it loads after `corex-core`:
```cfg
ensure corex-core
ensure corex-loot
```

`corex-core` is the only manifest dependency. Loot deliberately does not name a
specific inventory resource: item operations use the CoreX inventory bridge so
the selected provider can be replaced without making Loot fail to start.

If no usable inventory provider is available, item operations must fail
truthfully; this resource does not maintain a second hidden item store.

## Update

Use a matching reviewed COREX build. Back up `config.lua` before merging local
loot-table or world-location changes. This README does not imply a published
release or connected gameplay acceptance.

## Docs
📖 <https://corex-zombies.gitbook.io/corex-docs/reference/loot>

## Community
💬 <https://discord.gg/G95rtnb9sg>

## License
Released under the [MIT License](LICENSE).
