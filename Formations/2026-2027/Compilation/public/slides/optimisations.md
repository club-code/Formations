# Optimisations

---

## `-O0` vs `-O2`

<div class="cols">
<div>

<p><code>-O0</code></p>
<p class="big">~30 lignes</p>

</div>
<div class="fragment">

<p><code>-O2</code></p>

```llvm
define i32 @main() {
entry:
  ret i32 5
}
```

</div>
</div>

<div class="passes fragment">
<span class="pass">mem2reg</span> → <span class="pass">indvars</span> → <span class="pass">loop-deletion</span> → <span class="pass">simplifycfg</span>
</div>

---

<!-- .slide: class="small-code" -->

## mem2reg

<div class="passes"><span class="pass current">mem2reg</span> → <span class="pass">indvars</span> → <span class="pass">loop-deletion</span> → <span class="pass">simplifycfg</span></div>

<p class="desc">Plus de <code>load</code> ni de <code>store</code>.</p>

<div class="cols">
<div class="grow">

```llvm [|5-6]
define i32 @main() {
entry:
  br label %for.cond
for.cond:
  %theo.0 = phi i32 [ 0, %entry ], [ %inc, %for.inc ]
  %i.0 = phi i32 [ 0, %entry ], [ %inc1, %for.inc ]
  %cmp = icmp slt i32 %i.0, 5
  br i1 %cmp, label %for.body, label %for.end
for.body:
  %inc = add nsw i32 %theo.0, 1
  br label %for.inc
for.inc:
  %inc1 = add nsw i32 %i.0, 1
  br label %for.cond
for.end:
  ret i32 %theo.0
}
```

</div>
<div class="small">

- Chaque registre n'est écrit qu'une fois (SSA)
- `phi` : vaut `0` au premier tour, puis la nouvelle valeur

</div>
</div>

---

<!-- .slide: class="small-code" -->

## indvars

<div class="passes"><span class="pass done">mem2reg</span> → <span class="pass current">indvars</span> → <span class="pass">loop-deletion</span> → <span class="pass">simplifycfg</span></div>

<p class="desc">Le compilateur calcule la valeur finale de <code>theo</code> sans faire tourner la boucle.</p>

<div class="cols">
<div class="small">

- `i` : 0 → 5
- `theo` : 0 → 5
- à la fin, `theo = 5`

</div>
<div class="grow">

```llvm [|11]
define i32 @main() {
entry:
  br label %for.cond
for.cond:
  br i1 false, label %for.body, label %for.end
for.body:
  br label %for.inc
for.inc:
  br label %for.cond
for.end:
  ret i32 5
}
```

</div>
</div>

---

## Nettoyage

<div class="passes"><span class="pass done">mem2reg</span> → <span class="pass done">indvars</span> → <span class="pass current">loop-deletion</span> → <span class="pass current">simplifycfg</span></div>

<p class="desc">La boucle ne sert plus à rien : on la supprime, puis on fusionne les blocs.</p>

<div class="cols">
<div>

<p class="small"><code>loop-deletion</code></p>

```llvm
define i32 @main() {
entry:
  br label %for.end
for.end:
  ret i32 5
}
```

</div>
<div class="fragment">

<p class="small"><code>simplifycfg</code></p>

```llvm
define i32 @main() {
entry:
  ret i32 5
}
```

</div>
</div>
