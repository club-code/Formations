# Mini-TP

---

## Mini-TP : les tokens

<p class="desc">Affichez les tokens produits par le lexer de clang</p>

```bash
clang -fsyntax-only -Xclang -dump-tokens main.c
```

<ol class="small">
<li class="fragment">Retrouvez la catégorie de <code>theo</code>, <code>5</code> et <code>++</code></li>
<li class="fragment">Remplacez <code>i ++</code> par <code>i++</code> : qu'est-ce qui change ?</li>
<li class="fragment">Quels tokens pour <code>a+++b</code> ? Et pour <code>int 3theo</code> ?</li>
</ol>

<p class="small fragment"><code>-fsyntax-only</code> : s'arrêter après l'analyse, sans générer de code</p>

---

## Mini-TP : l'AST

<p class="desc">Affichez l'AST construit par le parser de clang</p>

```bash
clang -fsyntax-only -Xclang -ast-dump main.c
clang -fsyntax-only -Xclang -ast-dump -Xclang -ast-dump-filter=main main.c
```

<ol class="small">
<li class="fragment">Retrouvez le <code>ForStmt</code> et ses enfants</li>
<li class="fragment">Transformez la boucle en <code>while</code> : comment change l'arbre ?</li>
<li class="fragment">Oubliez un <code>;</code> ou une <code>}</code> et lisez l'erreur</li>
</ol>

---

## Mini-TP : les erreurs sémantiques

<p class="desc">Ajoutez ces lignes une par une dans <code>main</code></p>

```bash
clang -fsyntax-only -Wall main.c
```

<table class="types">
<tr><td><code>return x;</code></td><td class="fragment">use of undeclared identifier</td></tr>
<tr><td><code>5++;</code></td><td class="fragment">expression is not assignable</td></tr>
<tr><td><code>return "theo";</code></td><td class="fragment">incompatible pointer to integer conversion</td></tr>
<tr><td><code>if (theo = 5) return 1;</code></td><td class="fragment">warning <code>-Wparentheses</code></td></tr>
</table>

<p class="small fragment">Dans l'AST, repérez les <code>ImplicitCastExpr</code> ajoutés par l'analyse sémantique</p>

---

## Mini-TP : générer l'IR

```bash
clang -S -emit-llvm -fno-discard-value-names main.c -o main.ll
```

<ol class="small">
<li class="fragment">Retrouvez les blocs <code>for.cond</code>, <code>for.body</code>, <code>for.inc</code>, <code>for.end</code></li>
<li class="fragment">Relancez sans <code>-fno-discard-value-names</code> : que deviennent les noms ?</li>
<li class="fragment">Réécrivez la boucle avec un <code>while</code> : combien de blocs ?</li>
</ol>

---

<!-- .slide: class="small-code" -->

## Mini-TP : Clang

```bash
clang -S -emit-llvm -O0 -Xclang -disable-O0-optnone main.c -o main.ll
opt -S -passes=mem2reg main.ll
opt -S -passes=mem2reg,indvars main.ll
opt -S -passes=mem2reg,indvars,loop-deletion,simplifycfg main.ll
```

<ol class="small">
<li class="fragment">Appliquez les passes une par une et comparez avec les slides</li>
<li class="fragment">Retirez <code>-disable-O0-optnone</code> : pourquoi <code>opt</code> ne fait plus rien ?</li>
<li class="fragment">Comparez avec <code>clang -S -emit-llvm -O2 main.c -o -</code></li>
</ol>

---

```bash
clang -S -O0 -masm=intel main.c -o -
clang -S -O2 -masm=intel main.c -o -
```

<p class="fragment small">À <code>-O2</code>, il ne reste que <code>mov eax, 5</code> et <code>ret</code></p>

<p class="fragment small">Remplacez <code>5</code> par <code>argc</code> et <code>theo++</code> par <code>theo += i</code> : la boucle disparaît-elle encore ?</p>
