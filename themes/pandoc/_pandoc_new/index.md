---
title: Pandoc "NEW" style README
date: 2024-11-25
author: Harukamy
---

# Pandoc New Style

Pandoc new style is a new theme base for Pandoc processors, adopted from PureBuilder Simply 3.3.
It is used in themes such as COOLDARK and PAPER, which have been available since PureBuilder Simply 3.3.

# menu.yaml

In the Pandoc new style theme, you can control the menu displayed at the top by editing menu.yaml.

For example

```yaml
---
- path: /
  name: Top
- path: /about
  name: About us
```

If there are no items you wish to display in the menu, do the following

```yaml
---
[]
```