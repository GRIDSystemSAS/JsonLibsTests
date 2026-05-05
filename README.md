<div align="right">

[🇫🇷 Version Française ↓](#-version-française)

</div>

# JsonLibsTests

# Pascal Delphi/FPC project for JSON RFC 8259 coverage.

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

Here are the listed librairies: (no date -> owned repo, no repo available)

```
Lib                                      Upstream                                         Updated
---------------------------------------  -----------------------------------------------  ----------
gsJson (gsJson (native))                 https://github.com/GRIDSystemSAS/JsonLibsTests
embDelphiJson (Embarcadero System.JSON)
bero (PasJSON)                           https://github.com/BeRo1985/pasjson              2026-05-05
chimera (Chimera JSON)
dwsJson (DWScript JSON)                  https://github.com/EricGrange/DWScript           2026-05-05
dynamicDataObjects (DataObjects2)
grijjyBson (Grijjy.Foundation BSON)      https://github.com/grijjy/GrijjyFoundation       2026-05-05
jdo (JsonDataObjects)                    https://github.com/ahausladen/JsonDataObjects    2026-05-05
json4Delphi (JSON4Delphi (Jsons))
jsonDoc                                  https://github.com/stijnsanders/jsonDoc          2026-05-05
lkJson
mcJson
mormot (mORMot 2)                        https://github.com/synopse/mORMot2               2026-05-05
myJson
neslibJson (Neslib.Json)                 https://github.com/neslib/Neslib.Json            2026-05-05
superObject                              https://github.com/hgourvest/superobject
uJson
vsoftYaml (VSoft.YAML)                   https://github.com/VSoftTechnologies/VSoft.YAML  2026-05-05
xSuperObject                             https://github.com/onryldz/x-superobject         2026-05-05
```

# How to use

After compiling the project (main source is tests/gsJsonTests.dpr), you can run the tests with the command
```
gsJsonTests.exe -pp -nw
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


Here is the output of the program after a test launched on 05/05/2026.

```
  igsJson - RFC 8259 Compliance Test Results
  ==========================================

+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
| #  |  Backend              | Factory ID            | Pass | Fail | Error | Total | Score  |  Time  |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
|  1 | dwsJson               | dwsjson               |   62 |    0 |     0 |    62 | 100,0% | 0,016s |
|  2 | gsJson                | gsjson                |   62 |    0 |     0 |    62 | 100,0% | 0,015s |
|  3 | jdo                   | jdo                   |   62 |    0 |     0 |    62 | 100,0% | 0,014s |
|  4 | xSuperObject          | xsuperobject          |   62 |    0 |     0 |    62 | 100,0% | 0,019s |
|  5 | beroJson              | berojson              |   61 |    1 |     0 |    62 |  98,4% | 0,017s |
|  6 | embarcaderoDelphiJson | embarcaderoDelphiJson |   61 |    1 |     0 |    62 |  98,4% | 0,014s |
|  7 | grijjyBson            | grijjybson            |   61 |    1 |     0 |    62 |  98,4% | 0,014s |
|  8 | vsoftYaml             | vsoftyaml             |   61 |    1 |     0 |    62 |  98,4% | 0,016s |
|  9 | neslibJson            | neslibjson            |   60 |    2 |     0 |    62 |  96,8% | 0,015s |
| 10 | dynamicDataObjects    | dynamicdataobjects    |   59 |    1 |     2 |    62 |  95,2% | 0,016s |
| 11 | lkJson                | lkjson                |   59 |    3 |     0 |    62 |  95,2% | 0,015s |
| 12 | superObject           | superobject           |   59 |    3 |     0 |    62 |  95,2% | 0,013s |
| 13 | mormot2               | mormot2               |   56 |    6 |     0 |    62 |  90,3% | 0,015s |
| 14 | mcJson                | mcjson                |   55 |    2 |     5 |    62 |  88,7% | 0,017s |
| 15 | chimera               | chimera               |   54 |    5 |     3 |    62 |  87,1% | 0,017s |
| 16 | json4Delphi           | json4delphi           |   52 |    2 |     8 |    62 |  83,9% | 0,016s |
| 17 | myJson                | myjson                |   49 |    6 |     7 |    62 |  79,0% | 0,019s |
| 18 | jsonDoc               | jsondoc               |   45 |    2 |    15 |    62 |  72,6% | 0,019s |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
|    | TOTAL                 |                       | 1040 |   36 |    40 |  1116 |  93,2% | 0,284s |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
```


---

<br>

# 🇫🇷 Version française

<div align="right">

[↑ Back to top / English version](#jsonlibstests)

</div>

# Un projet JSON pour Pascal Delphi/FPC qui cible la conformité RFC 8259.

## Contexte

Au fil des années, sur nos projets Pascal/Delphi chez Grid System, nous avons
croisé des dizaines de bibliothèques JSON. Chacune avec son approche —
certaines performantes, d'autres surprenantes, toutes demandant un vrai travail
d'adaptation pour être intégrées.

Pour limiter la dette technique sur nos projets majeurs, nous avons fini par
concevoir une interface de classe commune qui abstrait la bibliothèque JSON
sous-jacente. À plusieurs reprises, cela a été salvateur : nous avons pu
remplacer la bibliothèque d'origine par une autre plus adaptée sur certains
points d'un projet, sans toucher au code métier.

Nous publions aujourd'hui en open source cette interface, accompagnée d'un
outil qui évalue le respect strict de la
[RFC 8259](https://datatracker.ietf.org/doc/html/rfc8259) par chaque
bibliothèque backend.

## Ce que ce dépôt est — et n'est pas

**Périmètre**

- L'interface front commune, que nous souhaitons continuer d'améliorer.
- Le respect strict de la RFC 8259, qui est important dans les domaines où
  nous travaillons.

**Hors périmètre**

- **Pas de test de performance.** Toutes les bibliothèques sont pilotées via
  notre interface commune, qui peut elle-même introduire un coût dans certains
  cas. Publier des chiffres bruts dans ce contexte serait trompeur.

## Compatibilité Pascal

L'interface et le runner de tests visent à la fois Delphi et FPC. Les
bibliothèques backend, en revanche, sont utilisées telles quelles : toutes ne
compilent pas forcément sur les deux compilateurs, et nous n'y touchons pas.

## Bibliothèques évaluées (pas de date "updated" ->soit repos interne, soit pas de repo localisable)

```
Lib                                      Upstream                                         Updated
---------------------------------------  -----------------------------------------------  ----------
gsJson (gsJson (native))                 https://github.com/GRIDSystemSAS/JsonLibsTests
embDelphiJson (Embarcadero System.JSON)
bero (PasJSON)                           https://github.com/BeRo1985/pasjson              2026-05-05
chimera (Chimera JSON)
dwsJson (DWScript JSON)                  https://github.com/EricGrange/DWScript           2026-05-05
dynamicDataObjects (DataObjects2)
grijjyBson (Grijjy.Foundation BSON)      https://github.com/grijjy/GrijjyFoundation       2026-05-05
jdo (JsonDataObjects)                    https://github.com/ahausladen/JsonDataObjects    2026-05-05
json4Delphi (JSON4Delphi (Jsons))
jsonDoc                                  https://github.com/stijnsanders/jsonDoc          2026-05-05
lkJson
mcJson
mormot (mORMot 2)                        https://github.com/synopse/mORMot2               2026-05-05
myJson
neslibJson (Neslib.Json)                 https://github.com/neslib/Neslib.Json            2026-05-05
superObject                              https://github.com/hgourvest/superobject
uJson
vsoftYaml (VSoft.YAML)                   https://github.com/VSoftTechnologies/VSoft.YAML  2026-05-05
xSuperObject                             https://github.com/onryldz/x-superobject         2026-05-05
```

## Comment l'utiliser

Après compilation du projet (source principale : `tests/gsJsonTests.dpr`), vous
pouvez lancer les tests avec la commande :

~~~
gsJsonTests.exe -pp -nw
~~~

### Lire les résultats

Chaque bibliothèque est évaluée sur le même jeu de tests RFC 8259.
Trois issues sont possibles :

- **Pass** — la bibliothèque a traité l'entrée conformément à la RFC.
- **Fail** — la bibliothèque a produit un résultat, mais non conforme à la
  RFC (par exemple, elle accepte un document invalide, ou refuse un document
  valide).
- **Error** — la bibliothèque a levé une exception, crashé, ou n'a tout
  simplement pas pu produire de réponse exploitable.

`Fail` est donc un signal de *conformité* vis-à-vis de la spec, tandis
qu'`Error` est un signal de *robustesse* de la bibliothèque elle-même. Les
deux pénalisent le score.

Voici la sortie du programme après une exécution lancée le 05/05/2026 :

~~~
  igsJson - RFC 8259 Compliance Test Results
  ==========================================

+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
| #  |  Backend              | Factory ID            | Pass | Fail | Error | Total | Score  |  Time  |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
|  1 | dwsJson               | dwsjson               |   62 |    0 |     0 |    62 | 100,0% | 0,016s |
|  2 | gsJson                | gsjson                |   62 |    0 |     0 |    62 | 100,0% | 0,015s |
|  3 | jdo                   | jdo                   |   62 |    0 |     0 |    62 | 100,0% | 0,014s |
|  4 | xSuperObject          | xsuperobject          |   62 |    0 |     0 |    62 | 100,0% | 0,019s |
|  5 | beroJson              | berojson              |   61 |    1 |     0 |    62 |  98,4% | 0,017s |
|  6 | embarcaderoDelphiJson | embarcaderoDelphiJson |   61 |    1 |     0 |    62 |  98,4% | 0,014s |
|  7 | grijjyBson            | grijjybson            |   61 |    1 |     0 |    62 |  98,4% | 0,014s |
|  8 | vsoftYaml             | vsoftyaml             |   61 |    1 |     0 |    62 |  98,4% | 0,016s |
|  9 | neslibJson            | neslibjson            |   60 |    2 |     0 |    62 |  96,8% | 0,015s |
| 10 | dynamicDataObjects    | dynamicdataobjects    |   59 |    1 |     2 |    62 |  95,2% | 0,016s |
| 11 | lkJson                | lkjson                |   59 |    3 |     0 |    62 |  95,2% | 0,015s |
| 12 | superObject           | superobject           |   59 |    3 |     0 |    62 |  95,2% | 0,013s |
| 13 | mormot2               | mormot2               |   56 |    6 |     0 |    62 |  90,3% | 0,015s |
| 14 | mcJson                | mcjson                |   55 |    2 |     5 |    62 |  88,7% | 0,017s |
| 15 | chimera               | chimera               |   54 |    5 |     3 |    62 |  87,1% | 0,017s |
| 16 | json4Delphi           | json4delphi           |   52 |    2 |     8 |    62 |  83,9% | 0,016s |
| 17 | myJson                | myjson                |   49 |    6 |     7 |    62 |  79,0% | 0,019s |
| 18 | jsonDoc               | jsondoc               |   45 |    2 |    15 |    62 |  72,6% | 0,019s |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
|    | TOTAL                 |                       | 1040 |   36 |    40 |  1116 |  93,2% | 0,284s |
+----+-----------------------+-----------------------+------+------+-------+-------+--------+--------+
~~~

## Contribuer

- Si vous maintenez l'une des bibliothèques testées et que vous publiez des
  changements, ils apparaîtront automatiquement lors de nos build de tests (on recupère les projet depuis leur source github).
  Les pull requests sont également bienvenues.

- ⭐ **Les stars aident à la visibilité.** Si le projet vous est utile, une
  étoile fait beaucoup. Merci !
  
