# LLVM IR

---

## Pourquoi une IR ?

<div class="pipeline">
<div class="stage">
C<br>C++<br>Rust<br>Swift
</div>
<div class="arrow">→</div>
<div class="stage accent">
LLVM IR
</div>
<div class="arrow">→</div>
<div class="stage">
x86<br>ARM<br>RISC-V<br>WebAssembly
</div>
</div>

---

## Blocs de base

<svg class="cfg" viewBox="0 0 620 410" role="img" aria-label="Graphe de flot de contrôle de la boucle for">
<defs>
<marker id="cfg-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
<path d="M0,0 L10,5 L0,10 z" class="head"/>
</marker>
</defs>
<rect x="160" y="5" width="220" height="64"/>
<text x="270" y="30" class="name">entry</text>
<text x="270" y="58" class="code">theo = 0; i = 0</text>
<rect x="160" y="115" width="220" height="64"/>
<text x="270" y="140" class="name">for.cond</text>
<text x="270" y="168" class="code">i &lt; 5 ?</text>
<rect x="160" y="230" width="220" height="64"/>
<text x="270" y="255" class="name">for.body</text>
<text x="270" y="283" class="code">theo++</text>
<rect x="160" y="340" width="220" height="64"/>
<text x="270" y="365" class="name">for.inc</text>
<text x="270" y="393" class="code">i++</text>
<rect x="420" y="230" width="190" height="64"/>
<text x="515" y="255" class="name">for.end</text>
<text x="515" y="283" class="code">return theo</text>
<path d="M270 69 L270 113"/>
<path d="M270 179 L270 228" class="yes"/>
<text x="282" y="210" class="label yes">vrai</text>
<path d="M380 147 L515 147 L515 228" class="no"/>
<text x="440" y="138" class="label no">faux</text>
<path d="M270 294 L270 338"/>
<path d="M160 372 L110 372 L110 147 L158 147"/>
</svg>

---

<!-- .slide: class="tiny-code" -->

## L'IR simplifié

<div class="cols">
<div class="grow">

```llvm [|2-7|9-12|14-18|20-24|26-28]
define i32 @main() {
entry:
  %theo = alloca i32             ; int theo;
  %i    = alloca i32             ; int i;
  store i32 0, ptr %theo         ; theo = 0
  store i32 0, ptr %i            ; i = 0
  br label %for.cond

for.cond:
  %0   = load i32, ptr %i
  %cmp = icmp slt i32 %0, 5      ; i < 5
  br i1 %cmp, label %for.body, label %for.end

for.body:
  %1   = load i32, ptr %theo
  %inc = add i32 %1, 1
  store i32 %inc, ptr %theo      ; theo++
  br label %for.inc

for.inc:
  %2    = load i32, ptr %i
  %inc1 = add i32 %2, 1
  store i32 %inc1, ptr %i        ; i++
  br label %for.cond

for.end:
  %3 = load i32, ptr %theo
  ret i32 %3                     ; return theo
}
```

</div>
<div class="small">

- `alloca` : réserver
- `load` : lire
- `store` : écrire
- `icmp` : comparer
- `br` : sauter

</div>
</div>

---

<!-- .slide: class="tiny-code" -->

## La vraie sortie

```llvm [|3,6|18,24|1,26]
define dso_local i32 @main() #0 {
entry:
  %retval = alloca i32, align 4
  %theo = alloca i32, align 4
  %i = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  store i32 0, ptr %theo, align 4
  store i32 0, ptr %i, align 4
  br label %for.cond

for.cond:
  %0 = load i32, ptr %i, align 4
  %cmp = icmp slt i32 %0, 5
  br i1 %cmp, label %for.body, label %for.end

for.body:
  %1 = load i32, ptr %theo, align 4
  %inc = add nsw i32 %1, 1
  store i32 %inc, ptr %theo, align 4
  br label %for.inc

for.inc:
  %2 = load i32, ptr %i, align 4
  %inc1 = add nsw i32 %2, 1
  store i32 %inc1, ptr %i, align 4
  br label %for.cond, !llvm.loop !6

for.end:
  %3 = load i32, ptr %theo, align 4
  ret i32 %3
}
```

---

## Récap

| C | AST | IR |
|---|---|---|
| `int theo = 0;` | `VarDecl` | `alloca` + `store` |
| `i < 5` | `BinaryOperator` | `load` + `icmp` |
| `theo++` | `UnaryOperator` | `load` + `add` + `store` |
| `for` | `ForStmt` | 4 blocs |
| `return theo;` | `ReturnStmt` | `load` + `ret` |

<!-- .element: class="small" -->
