# Analyse sémantique

```c
int main() {
    int theo = 0;
    for (int i  = 0; i < 5; i ++){
        theo ++;
    }
    return theo;
}
```

---

## Ça compile ?

<div class="cols errors">
<div>

```c
    }
    return i;
```

<p class="error">use of undeclared identifier 'i'</p>

</div>
<div class="fragment">

```c
    for (...){
        5 ++;
```

<p class="error">expression is not assignable</p>

</div>
<div class="fragment">

```c
    }
    return "theo";
```

<p class="error">incompatible pointer to integer conversion</p>

</div>
</div>

---

## Portée

<div class="cols">
<div class="scope">
<div class="scope-label">main</div>
<code>int theo = 0;</code>
<div class="scope inner">
<div class="scope-label">for</div>
<code>int i = 0; i &lt; 5; i++</code>
<code>theo++;</code>
</div>
<code>return theo;</code>
</div>
<div>
<table class="symbols">
<thead><tr><th>Portée</th><th>Nom</th><th>Type</th></tr></thead>
<tbody>
<tr><td>main</td><td>theo</td><td>int</td></tr>
<tr class="fragment"><td>for</td><td>i</td><td>int</td></tr>
</tbody>
</table>
</div>
</div>

---

## Types

<table class="types">
<tr><td><code>i &lt; 5</code></td><td>✔</td></tr>
<tr><td><code>theo++</code></td><td>✔</td></tr>
<tr class="fragment"><td><code>5++</code></td><td>✘ pas une variable</td></tr>
<tr class="fragment"><td><code>return "theo"</code></td><td>✘ <code>char[5]</code> ≠ <code>int</code></td></tr>
</table>

---

<!-- .slide: class="small-code" -->

## L'AST de clang

```plaintext [|4,8|13,16,19|12,21]
FunctionDecl main 'int ()'
`-CompoundStmt
  |-DeclStmt
  | `-VarDecl used theo 'int' cinit
  |   `-IntegerLiteral 'int' 0
  |-ForStmt
  | |-DeclStmt
  | | `-VarDecl used i 'int' cinit
  | |   `-IntegerLiteral 'int' 0
  | |-<<<NULL>>>
  | |-BinaryOperator 'int' '<'
  | | |-ImplicitCastExpr 'int' <LValueToRValue>
  | | | `-DeclRefExpr 'int' lvalue Var 'i' 'int'
  | | `-IntegerLiteral 'int' 5
  | |-UnaryOperator 'int' postfix '++'
  | | `-DeclRefExpr 'int' lvalue Var 'i' 'int'
  | `-CompoundStmt
  |   `-UnaryOperator 'int' postfix '++'
  |     `-DeclRefExpr 'int' lvalue Var 'theo' 'int'
  `-ReturnStmt
    `-ImplicitCastExpr 'int' <LValueToRValue>
      `-DeclRefExpr 'int' lvalue Var 'theo' 'int'
```
