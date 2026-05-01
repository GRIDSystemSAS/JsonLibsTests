<div align="right">

[🇫🇷 Version Française ↓](#-version-française)

</div>

# JsonLibsTests

## Context

Over the years, working at Grid System on Pascal/Delphi projects, we have crossed
paths with dozens of JSON libraries. Each of them came with its own approach —
some fast, some surprising, all requiring real adaptation work to plug in.

To keep technical debt under control on our larger projects, we ended up
designing a common class interface that abstracts the underlying JSON library.
On several occasions this paid off: we were able to swap the original library
for a more suitable one on specific parts of a project, without rewriting
business code.

We are now releasing the open source version of this work: the front interface
itself, and a tool that evaluates how strictly each backend library follows
[RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259).

## What this repository is — and is not

**Focus**

- The common front interface, which we want to keep refining.
- Strict RFC 8259 conformance, which matters a lot in the fields we work in.

**Out of scope**

- **No performance benchmark.** All libraries are driven through our common
  interface, which can itself introduce overhead in some cases. Reporting raw
  numbers in this setup would be misleading.

## Pascal compatibility

The interface and the test runner target both Delphi and FPC. Backend
libraries, however, are used as-is: not all of them compile on both
compilers, and we do not patch them.

## Contributing

- If you maintain one of the tested libraries and you ship changes, please let
  us know — we will refresh the git tree on our side. Pull requests are also
  very welcome.
- ⭐ **Stars help visibility.** If this project is useful to you, a star goes
  a long way. Thanks!


  
# JsonLibsTests

## What is it

This project allows testing the [RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259) coverage for Delphi JSON libraries listed on Github.

Here are the listed librairies:

| Librairy| Repository| Branch | Note |
| --- | --- | --- | --- |
| chimera | https://github.com/jbsolucoes/jsonchimera | master |  |
| dwsJson| https://github.com/EricGrange/DWScript | master | |
| dynamicDataObjetcs | https://github.com/SeanSolberg/DynamicDataObjects | master | |
| grijjyBson | https://github.com/grijjy/GrijjyFoundation | master | |
| jdo |  https://github.com/ahausladen/jsondataObjects | master | |
| json4Delphi | https://github.com/rilyu/json4delphi | master |  |
| jsonDoc | https://github.com/stijnsanders/jsonDoc | master | |
| jsonTools | https://github.com/sysrpl/JsonTools | master | The library had to be fixed. |
| mcJson | https://github.com/hydrobyte/McJSON | main | |
| mormot2 | https://github.com/synopse/mORMot2 | master |  |
| myJson | https://github.com/badunius/myJSON | master | |
| neslibJson | https://github.com/neslib/Neslib.Json | master | |
|  | https://github.com/neslib/Neslib | master | |
| superObject | https://github.com/pult/SuperObject.Delphi | master | |
| uJson | https://github.com/diffbot/diffbot-delphi-client | master | |
| vsoftYaml | https://github.com/VSoftTechnologies/VSoft.YAML | main | |
| xSuperObject | https://github.com/onryldz/x-superobject | master | |
| bero | https://github.com/BeRo1985/pasjson | master | |
| | https://github.com/BeRo1985/pasdblstrutils | master | |
| lkJson | https://sourceforge.net/projects/lkjson/ | N/A | No github project |

# How to use

After compiling the project (main source is tests/gsJsonTests.dpr), you can run the tests with the command
```
gsJsonTests.exe -pp -nw
```

Here is the output of the program after a test launched on 27/04/2026.

```
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
| #  |  Backend              | Factory ID            | Pass | Fail | Error | Total | Score  |  Time  |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
|  1 | dwsJson               | dwsjson               |   62 |    0 |     0 |    62 | 100,0% | 0,026s |
|  2 | gsJson                | gsjson                |   62 |    0 |     0 |    62 | 100,0% | 0,026s |
|  3 | jdo                   | jdo                   |   62 |    0 |     0 |    62 | 100,0% | 0,024s |
|  4 | xSuperObject          | xsuperobject          |   62 |    0 |     0 |    62 | 100,0% | 0,026s |
|  5 | beroJson              | berojson              |   61 |    1 |     0 |    62 |  98,4% | 0,026s |
|  6 | embarcaderoDelphiJson | embarcaderoDelphiJson |   61 |    1 |     0 |    62 |  98,4% | 0,025s |
|  7 | grijjyBson            | grijjybson            |   61 |    1 |     0 |    62 |  98,4% | 0,026s |
|  8 | neslibJson            | neslibjson            |   60 |    2 |     0 |    62 |  96,8% | 0,024s |
|  9 | vsoftYaml             | vsoftyaml             |   60 |    2 |     0 |    62 |  96,8% | 0,026s |
| 10 | dynamicDataObjects    | dynamicdataobjects    |   59 |    1 |     2 |    62 |  95,2% | 0,025s |
| 11 | lkJson                | lkjson                |   59 |    3 |     0 |    62 |  95,2% | 0,025s |
| 12 | superObject           | superobject           |   59 |    3 |     0 |    62 |  95,2% | 0,025s |
| 13 | mormot2               | mormot2               |   56 |    6 |     0 |    62 |  90,3% | 0,025s |
| 14 | mcJson                | mcjson                |   55 |    2 |     5 |    62 |  88,7% | 0,026s |
| 15 | chimera               | chimera               |   54 |    5 |     3 |    62 |  87,1% | 0,026s |
| 16 | json4Delphi           | json4delphi           |   52 |    2 |     8 |    62 |  83,9% | 0,025s |
| 17 | jsonTools             | jsontools             |   50 |    5 |     7 |    62 |  80,6% | 0,026s |
| 18 | myJson                | myjson                |   48 |    6 |     8 |    62 |  77,4% | 0,027s |
| 19 | jsonDoc               | jsondoc               |   45 |    2 |    15 |    62 |  72,6% | 0,027s |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
|    | TOTAL                 |                       | 1088 |   42 |    48 |  1178 |  92,4% | 0,486s |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
```

### Reading the results

Each library is evaluated against the same set of RFC 8259 test cases.
Three outcomes are possible:

- **Pass** — the library handled the input as the RFC requires.
- **Fail** — the library produced a result, but one that does not conform to
  the RFC (e.g. it accepted an invalid document, or rejected a valid one).
- **Error** — the library raised an exception, crashed, or otherwise failed
  to produce a usable answer on the input.

`Fail` is therefore a *correctness* signal against the spec, while `Error` is
a *robustness* signal about the library itself. Both count against the score.
