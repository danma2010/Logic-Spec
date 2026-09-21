---
name: <unit>
vendor: xilinx            # xilinx | altera
kind: leaf                # leaf | composite | top
status: planned           # planned | generated | validated
dependencies: []          # names of VALIDATED units instantiated (direct RTL)
ports: []                 # - { name: <port>, dir: in|out, width: <N> }
validated: {}             # { date: <YYYY-MM-DD>, tests: "<summary>" } when validated
---

# <unit> — Unit manifest

One-line purpose. `status` advances planned → generated → validated; only a
`validated` unit may be instantiated by another unit.
